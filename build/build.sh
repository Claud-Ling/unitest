#!/bin/bash

# ./build [arch/d/c/m/n/i/a/A/r/b/B/t/T/R/q/Q/u/h] [opt/targets]
# for unittest env build.
# Author:lingyun@cambricon.com, 202102

# run env.
THIS_FILE=`basename $0`
THIS_PATH=`cd "$(dirname $0)"; pwd`

# unittest root.
UT_ROOT=`dirname ${THIS_PATH}`

# unittest env subdir.
UT_DBUILD=build
UT_DRELEASE=release
UT_DTOOLS=tools
UT_DUTEST=utest

# unittest build env: build script,rules,output.
UTB_PATH=${UT_ROOT}/${UT_DBUILD}
UTB_DARCH=arch
UTB_DOUTPUT=output
UTB_DRULES=rules
UTB_DDOWN=down

UTB_PARCH=${UTB_PATH}/${UTB_DARCH}/arch
UTB_PCROSS=${UTB_PATH}/${UTB_DARCH}/cross

UTB_POUT=${UTB_PATH}/${UTB_DOUTPUT}/out
UTB_DOUT_TOOLS=${UTB_DOUTPUT}/out/tools
UTB_POUT_TOOLS=${UTB_PATH}/${UTB_DOUT_TOOLS}
UTB_DOUT_CMDS=${UTB_DOUTPUT}/out/commands
UTB_POUT_CMDS=${UTB_PATH}/${UTB_DOUT_CMDS}
UTB_PRELEASE=${UTB_PATH}/${UTB_DOUTPUT}/release

UTB_PRULES=${UTB_PATH}/${UTB_DRULES}
UTB_PDOWN=${UTB_PATH}/${UTB_DDOWN}

# unittest tools env: opensource tools.
UTT_PATH=${UT_ROOT}/${UT_DTOOLS}

# unittest utest env: test cases,commands source,scripts.
UTU_PATH=${UT_ROOT}/
UTU_DCASES=cases
UTU_DSCRIPTS=scripts
UTU_DCMDS=commands
UTU_FILES="utest README.md"

UTU_PCASES=${UTU_PATH}/${UTU_DCASES}
UTU_PSCRIPTS=${UTU_PATH}/${UTU_DSCRIPTS}
UTU_PCMDS=${UTU_PATH}/${UTU_DCMDS}

# unittest release env: all run files.
#UTR_PATH=${UT_ROOT}/${UT_DRELEASE}
UTR_PATH=${UTB_PRELEASE}
UTR_DCASES=cases
UTR_DSCRIPTS=scripts
UTR_DCMDS=commands
UTR_DTOOLS=tools

UTR_PCASES=${UTR_PATH}/${UTR_DCASES}
UTR_PSCRIPTS=${UTR_PATH}/${UTR_DSCRIPTS}
UTR_PCMDS=${UTR_PATH}/${UTR_DCMDS}
UTR_PTOOLS=${UTR_PATH}/${UTR_DTOOLS}

# build globe values.
BuildQuiet=0
BuildResMode=0
BuildTarMode=0
BuildArch=
BuildStepC=
BuildStepS=
RuleType=
RuleDTool=
RuleDURL=
RuleDPar=
RuleSrc=
RuleOut=
RulePSrc=
RulePOut=

# print define.
PDEBUG="[DBG] "
PERROR="[**] "
PINFO="[--] "
PEXEC="[++] "

# function of echo debug msg.
# $@ - debug msg.
# $? - 0-OK.
echoD() {
	echo "${PDEBUG}$@"
	#return 0
}

# function of error echo.
# $@ - string to be print.
# $? - none
function echoE() {
    echo "${PERROR}$@"
}

# function of info echo.
# $@ - string to be print.
# $? - none
function echoI() {
    if [ ${BuildQuiet} -lt 2 ]; then
        echo "${PINFO}$@"
    fi
}

# function of run line for quiet out.
# $@ - exec line to be run.
# $? - 0-OK,1-ERROR.
function execQline() {
    if [ ${BuildQuiet} -lt 2 ]; then
        echo "${PEXEC}$@"
    fi
    if [ ${BuildQuiet} -gt 1 ]; then
        $@ >/dev/null 2>&1
    elif [ ${BuildQuiet} -gt 0 ]; then
        $@ >/dev/null
    else
        $@
    fi
    return $?
}

# function of flush arch config for build.
# $? - 0-OK, 1-error.
function ArchFlush () {
    BuildArchNew=`${UTB_PARCH} s`
    if [ -z "${BuildArchNew}" ]; then
        echo "arch not config"
        return 1
    else
        #echoI "arch flush to ${BuildArchNew}"
        OutArch=${UTB_POUT}-${BuildArchNew}
        if [ ! -d ${OutArch} ]; then
            mkdir -p ${OutArch}
        fi
        if [ -h ${UTB_POUT} ]; then
            OutArchLink=`readlink ${UTB_POUT}`
            if [ ! `basename ${OutArch}` == ${OutArchLink} ]; then
                rm ${UTB_POUT}
                ln -sf `basename ${OutArch}` ${UTB_POUT}
            fi
        else
            ln -sf `basename ${OutArch}` ${UTB_POUT}
        fi
        if [ ! -d ${UTB_POUT_TOOLS} ]; then
            mkdir -p ${UTB_POUT_TOOLS}
        fi
        if [ ! -d ${UTB_POUT_CMDS} ]; then
            mkdir -p ${UTB_POUT_CMDS}
        fi
        BuildArch=${BuildArchNew}
        return 0
    fi
}

# function of exec arch script, and flush if changed.
# $1 - arch script $1, more see ${UTB_PARCH}
# $? - 0-OK, 1-error.
function ArchExec () {
    if [ -x ${UTB_PARCH}  ]; then
        ${UTB_PARCH} $1
        BuildArchNew=`${UTB_PARCH} s`
        if [ "${BuildArch}" == ${BuildArchNew} ]; then
            return 0
        else
            ArchFlush
            return $?
        fi
    else
        echoE "${UTB_PARCH} cant't exec"
        return 1
    fi
}

# function of down with git.
# $1 - git remote URL(http/ssh).
# $2 - local repo path, null for ${UTT_PATH}.
# $3 - local repo name, null for default from URL.
# $4 - checkout branch, nulll for default.
# $? - 0-OK, 1-ERROR.
function DownWithGit() {
    if [ -z "$1" ]; then
        echoE "no git url."
        return 1
    fi
    if [ -z "$2" ]; then
        SrcPath=$(UTT_PATH)
    else
        SrcPath=$2
    fi
    if [ -z "$3" ]; then
        GitRepo=$(basename $1 .git)
    else
        GitRepo=$3
    fi
    echoI "down git: $1 $4 -> ${GitRepo}"
    PwdPreGit=`pwd`
	if [ ! -d ${SrcPath} ]; then
		mkdir -p ${SrcPath}
	fi
    cd ${SrcPath}
    if [ -d ${GitRepo} ]; then
        cd ${GitRepo}
        if [ ! -z "$4" ]; then
            execQline git checkout $4
            if [ $? -gt 0 ]; then
                cd ${PwdPreGit}
                return 1
            fi
        fi
        execQline git pull
        if [ $? -gt 0 ]; then
            cd ${PwdPreGit}
            return 1
        fi
    else
        execQline git clone $1 ${GitRepo}
        if [ $? -gt 0 ]; then
            cd ${PwdPreGit}
            return 1
        fi
        if [ ! -z "$4" ]; then
            cd ${GitRepo}
            execQline git checkout $4
            if [ $? -gt 0 ]; then
                cd ${PwdPreGit}
                return 1
            fi
        fi
    fi
    cd ${PwdPreGit}
    return 0
}

# function of down with wget.
# $1 - wget http URL.
# $2 - local repo path, null for ${UTT_PATH}.
# $3 - local repo name, null for default from URL.
# $4 - wget local file name, empty for default.
# $? - 0-OK, 1-ERROR.
function DownWithWget() {
    if [ -z "$1" ]; then
        echoE "no wget url."
        return 1
    fi
    if [ -z "$2" ]; then
        SrcPath=$(UTT_PATH)
    else
        SrcPath=$2
    fi
    if [ -z "$4" ]; then
        SrcPkg=$(basename $1)
        WgetOut=
    else
        SrcPkg=$4
        WgetOut="-o ${SrcPkg}"
    fi
    SrcRepo=$(basename ${SrcPkg} .xz)
    SrcRepo=$(basename ${SrcRepo} .gz)
    SrcRepo=$(basename ${SrcRepo} .bz2)
    SrcRepo=$(basename ${SrcRepo} .tar)
    SrcRepo=$(basename ${SrcRepo} .tgz)
    echoI "down wget: $1 -> ${SrcRepo}"
    PwdPreWget=`pwd`
	if [ ! -d ${UTB_PDOWN} ]; then
		mkdir -p ${UTB_PDOWN}
	fi
    cd ${UTB_PDOWN}
    if [ ! -f ${SrcPkg} ]; then
        execQline wget "$1" ${WgetOut}
        if [ $? -gt 0 ]; then
            cd ${PwdPreWget}
            return 1
        fi
    fi
    if [ ! -f ${SrcPkg} ]; then
        echoE "wget error"
        cd ${PwdPreWget}
        return 1
    fi
	if [ ! -d ${SrcPath} ]; then
		mkdir -p ${SrcPath}
	fi
    cd ${SrcPath}
    if [ -e ${SrcRepo} ]; then
        echoI "rm: ${SrcRepo}"
        rm -fr ${SrcRepo}
    fi
    echoI "tar: ${SrcPkg} -> ${SrcRepo}"
    if [[ "${SrcPkg}" =~ ".gz" ]] || [[ "${SrcPkg}" =~ ".tgz" ]]; then
        tar -zxf ${UTB_PDOWN}/${SrcPkg} ${SrcRepo}
    elif [[ "${SrcPkg}" =~ ".bz2" ]]; then
        tar -jxf ${UTB_PDOWN}/${SrcPkg} ${SrcRepo}
    else
        tar -xf ${UTB_PDOWN}/${SrcPkg} ${SrcRepo}
    fi
    if [ ! -z "$3" ] && [ ! "${SrcRepo}" == "$3" ]; then
        echoI "mv: ${SrcRepo} -> $3"
        if [ -e $3 ]; then
            rm -fr $3
        fi
        mv ${SrcRepo} $3
    fi
    cd ${PwdPreWget}
    return 0
}

# Prepare cross arch before build.
ArchFlush
if [ -z "${BuildArch}" ]; then
    echoI "config arch first."
    ArchExec x
    ArchFlush
    if [ -z "${BuildArch}" ]; then
        echoE "config arch error."
        exit 1
    fi
fi
# sourece cross arch config.
. ${UTB_PCROSS}

# function of rules is support?
# $1 - rule name, see in ${UTB_PRULES}.
# $? - 0-not support, 1-support.
function RuleIsSupport() {
    if [ -z "$1" ] || [ ! -e "${UTB_PRULES}/$1" ]; then
        return 0
    else
        return 1
    fi
}

# function of rule's target is support?
# $1 - rule name, see in ${UTB_PRULES}.
# $2 - target name, rule_target() function.
# $? - 0-not support, 1-support.
function RuleTargetIsSupport() {
    if [ -z "$1" ] || [ -z "$2" ] ||
        [ ! "$(type -t $1_$2)" == function ]; then
        return 0
    else
        return 1
    fi
}

# function of config env called in rule_evn().
# $1 - rule type: tool/command, for RuleType.
# $2 - rule source dir: dir name, for RuleSrc.
# $3 - rule output dir: dir name, for RuleOut.
# $4 - rule down tool: git/wget, for RuleDTool.
# $5 - rule down URL: ssh/http, for RuleDURL.
# $6 - rule down par: branch/pkg, for RuleDPar.
# $? - 0-OK,1-ERROR.
function InRuleEnv() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echoE "EnvInRule error"
        return 1
    fi
    RuleSrc=$2
    if [ -z "$3" ]; then
        RuleOut=$RuleSrc
    else
        RuleOut=$3
    fi
    if [[ "$1" =~ "c" ]] ; then
        RuleType="C"
        RulePSrc=${UTU_PCMDS}/${RuleSrc}
        #RulePOut=${UTB_POUT_CMDS}/${RuleOut}
        RulePOut=${UTB_POUT_CMDS}
    else
        RuleType="T"
        RulePSrc=${UTT_PATH}/${RuleSrc}
        RulePOut=${UTB_POUT_TOOLS}/${RuleOut}
    fi
    if [ "$4" == "g" ] || [ "$4" == "git" ] ; then
        RuleDTool=DownWithGit
    elif [ "$4" == "w" ] || [ "$4" == "wget" ] ; then
        RuleDTool=DownWithWget
    else
        RuleDTool=
    fi
    RuleDURL=$5
    RuleDPar=$6
    return 0
}

# function of set enu for one rule.
# call rule_env() if define, else call InRuleEnv().
# $1 - rule name, see in ${UTB_PRULES}.
# $2 - add param if need.
# $? - 0-OK, 1-ERROR.
function RuleEnv() {
    RetVal=0
    RuleIsSupport $1
    if [ $? -gt 0 ]; then
        RuleTargetIsSupport $1 env
        if [ $? -gt 0 ]; then
            $1_env $2
            RetVal=$?
        else
            echoI "rule $1 env as command"
            InRuleEnv c $1
            RetVal=$?
        fi
    else
        echoE "rule $1 not support"
        RetVal=1
    fi
    #echoI "env-${RuleType} S:${RuleSrc} O:${RuleOut}"
    #echoI "src path: ${RulePSrc}"
    #echoI "out path: ${RulePOut}"
    #echoI "down: ${RuleDown} ${RuleDURL} ${RuleDPar}"
    return ${RetVal}
}

# function of config called in rule_conf().
# $1 - configure script
# $2 - patch file
# $3 - configure params
# $? - 0-OK,1-ERROR.
function InRuleConf() {
    RetVal=0
    if [ -z "$1" ] || [ ! -x $1 ] ; then
        echoE "Conf scipte $1 error"
        return 1
    fi
    if [ ! -z "$2" ] && [ -f "$2" ]; then
        patch -p1 < $2
    fi
    if [ -z "${CROSS_IS}" ]; then
        execQline ./$1 --prefix=${RulePOut} $3
        RetVal=$?
    else
        execQline ./$1 --prefix=${RulePOut} --host=${CROSS_COMPILE_HOST} $3
        RetVal=$?
    fi
    return ${RetVal}
}

# function of config for one rule.
# call rule_conf() if define, else drop.
# $1 - rule name, see in ${UTB_PRULES}.
# $2 - add param if need.
# $? - 0-OK, 1-ERROR.
function RuleConf() {
    RetVal=0
    RuleIsSupport $1
    if [ $? -gt 0 ]; then
        RuleTargetIsSupport $1 conf
        if [ $? -gt 0 ]; then
            echo "[${RuleType}C] $1 $2"
           $1_conf $2
            RetVal=$?
        fi
    else
        echoE "rule $1 not support"
        RetVal=1
    fi
    return ${RetVal}
}

# function of make target called in rule_make().
# $@ - make target or params.
# $? - 0-OK,1-ERROR.
function InRuleMake() {
    RetVal=0
    if [ -z "${CROSS_IS}" ]; then
        execQline make $@
        RetVal=$?
    else
        execQline make ARCH=${CROSS_ARCH} CROSS_COMPILE=${CROSS_COMPILE} $@
        RetVal=$?
    fi
    return ${RetVal}
}

# function of make for one rule.
# call rule_make() if define, else call InRuleMake().
# $1 - rule name, see in ${UTB_PRULES}.
# $@ - make target or params.
# $? - 0-OK, 1-ERROR.
function RuleMake() {
    RetVal=0
    RuleIsSupport $1
    if [ $? -gt 0 ]; then
        if [ $# -gt 1 ]; then
            Targets=`echo $@ |sed -e 's/[^ ]* //'`
        else
            Targets=
        fi
        echo "[${RuleType}M] $1 ${Targets}"
        RuleTargetIsSupport $1 make
        if [ $? -gt 0 ]; then
            $1_make ${Targets}
            RetVal=$?
        else
            echoI "rule $1 make as default"
            InRuleMake ${Targets}
            RetVal=$?
        fi
    else
        echoE "rule $1 not support"
        RetVal=1
    fi
    return ${RetVal}
}

# function of down for one rule if need.
# called after RuleEnv, and use RuleDxxx.
# $? - 0-OK, 1-ERROR.
function RuleDown() {
    if [ ! -z "${RuleDTool}" ]; then
        echo "[${RuleType}D] ${RuleDTool} ${RuleSrc}"
        ${RuleDTool} ${RuleDURL} `dirname ${RulePSrc}` ${RuleSrc} ${RuleDPar}
        return $?
    else
        return 0
    fi
}

# Prepare build rules before build
ToolList=$(ls ${UTB_PRULES} |grep -v commands |tr "\n" " ")

# source all support rules.
for Tool in ${ToolList}; do
    . ${UTB_PRULES}/${Tool}
done

# function of if target is tool?
# $1 - target name.
# $? - 0-no,1-yes.
function TargetIsTool() {
    if [ ! -z "$1" ]; then
        for Tool in ${ToolList}; do
            if [ "${Tool}" == "$1" ]; then
                return 1
            fi
        done
    fi
    return 0
}

# source commands rule.
CmdsList=
if [ -e ${UTB_PRULES}/commands ]; then
    . ${UTB_PRULES}/commands
fi
RuleIsSupport commands list
if [ $? -gt 0 ]; then
    commands_list
fi

# function of if target is commands?
# $1 - target name.
# $? - 0-no,1-yes.
function TargetIsCmds() {
    if [ ! -z "$1" ]; then
        for Cmd in ${CmdsList}; do
            if [ "${Cmd}" == "$1" ]; then
                return 1
            fi
        done
    fi
    return 0
}

# function of do build step.
# $1 - step pre return? 0-OK,1-ERROR.
# $2 - step list string.
# $3 - step flag char.
# $4 - step desp string.
# $5 - step exec line.
# $? - 0-OK,1-ERROR.
function DoBuildStep() {
    if [ $1 -gt 0 ]; then
        return $1
    fi
    BuildStepC=$3
    if [ -z "$4" ]; then
        BuildStepS=$3
    else
        BuildStepS=$4
    fi
    if [ -z "$3" ] || [ -z "$5" ]; then
        return 1
    fi
    if [[ "$2" =~ "${BuildStepC}" ]]; then
        #echoI "build step ${BuildStepC}(${BuildStepS}): $5"
        $5
        return $?
    fi
    return 0
}

# function of do build tool for targets.
# $1 - build opts: dcmnir
# $2 - build target tool
# $? - 0-OK,1-ERROR.
function DoBuildTool() {
    echo "[BT] $1: $2"
    if [ -z "$1" ] || [ -z "$2" ]; then
        retrun 1
    fi
    RetVal=0
    PwdPreDo=`pwd`
    DoBuildStep 0 e e env "RuleEnv $2"
    DoBuildStep $? $1 d down "RuleDown"
    DoBuildStep $? p p path "cd ${RulePSrc}"
    DoBuildStep $? $1 c conf "RuleConf $2"
    DoBuildStep $? $1 n clean "RuleMake $2 clean"
    DoBuildStep $? $1 m make "RuleMake $2"
    DoBuildStep $? $1 i install "RuleMake $2 install"
    RetVal=$?
    cd ${PwdPreDo}
    return ${RetVal}
}

# function of do build commands for targets.
# $1 - build opts: dcmnir
# $2 - build target command
# $? - 0-OK,1-ERROR.
function DoBuildCmds() {
    echo "[BC] $1: $2"
    if [ -z "$1" ] || [ -z "$2" ]; then
        retrun 1
    fi
    RetVal=0
    PwdPreDo=`pwd`
    DoBuildStep 0 e e env "RuleEnv commands $2"
    DoBuildStep $? $1 d down "RuleDown"
    DoBuildStep $? p p path "cd ${RulePSrc}"
    DoBuildStep $? $1 c conf "RuleConf commands $2"
    DoBuildStep $? $1 n clean "RuleMake commands $2 clean"
    DoBuildStep $? $1 m make "RuleMake commands $2"
    DoBuildStep $? $1 i install "RuleMake commands $2 install"
    RetVal=$?
    cd ${PwdPreDo}
    return ${RetVal}
}

# function of do build for targets.
# $1 - build opts: dcmnir
# $2 - build targets list
# $? - 0-OK,1-ERROR.
function DoBuild() {
    RetVal=0
    for Target in $2; do
        TargetValid=0
        TargetIsTool ${Target}
        if [ $? -gt 0 ]; then
            TargetValid=1
            DoBuildTool ${DoOpts} ${Target}
            if [ $? -gt 0 ]; then
                echo "[E${RuleType}] ${DoOpts}: ${Target} error ${BuildStepC}(${BuildStepS})"
                RetVal=1
                break
            fi
        fi
        if [ ${TargetValid} -eq 0 ]; then
            TargetIsCmds ${Target}
            if [ $? -gt 0 ]; then
                TargetValid=2
                DoBuildCmds ${DoOpts} ${Target}
                if [ $? -gt 0 ]; then
                    echo "[E${RuleType}] ${DoOpts}: ${Target} error ${BuildStepC}(${BuildStepS})"
                    RetVal=1
                    break
                fi
            fi
        fi
        if [ ${TargetValid} -eq 0 ]; then
            echoE "${DoOpts}: ${Target} not valid"
            RetVal=1
            break
        fi
    done
    return ${RetVal}
}

# function of do release with ln.
# $? - 0-OK,1-ERROR.
function DoReleaseLn() {
    echo "[RS] release with link for ${BuildArch}"
    mkdir -p ${UTR_PATH}
    # cases from utest/
    rm -fr ${UTR_PCASES}
    ln -sf ../${UT_DUTEST}/${UTU_DCASES} ${UTR_PCASES}
    # scripts form utest/
    rm -fr ${UTR_PSCRIPTS}
    ln -sf ../${UT_DUTEST}/${UTU_DSCRIPTS} ${UTR_PSCRIPTS}
    # files from utest/
    for File in ${UTU_FILES}; do
        rm -fr ${UTR_PATH}/${File}
        ln -sf ../${UT_DUTEST}/${File} ${UTR_PATH}/${File}
    done
    # commands from build/out/
    rm -fr ${UTR_PCMDS}
    ln -sf ../${UT_DBUILD}/${UTB_DOUT_CMDS} ${UTR_PCMDS}
    # tools from build/out/
    rm -fr ${UTR_PTOOLS}
    ln -sf ../${UT_DBUILD}/${UTB_DOUT_TOOLS} ${UTR_PTOOLS}
    return 0
}

# function of do release with cp.
# $? - 0-OK,1-ERROR.
function DoReleaseCp() {
    echo "[RS] release with copy for ${BuildArch}"
    mkdir -p ${UTR_PATH}
    # cases from utest/
    rm -fr ${UTR_PCASES}
    cp -fr ${UTU_PCASES} ${UTR_PATH}
    # scripts form utest/
    rm -fr ${UTR_PSCRIPTS}
    cp -fr ${UTU_PSCRIPTS} ${UTR_PATH}
    # files from utest/
    for File in ${UTU_FILES}; do
        rm -fr ${UTR_PATH}/${File}
        cp -fr ${UTU_PATH}/${File} ${UTR_PATH}
    done
    # commands from build/out/
    rm -fr ${UTR_PCMDS}
    cp -fr ${UTB_POUT_CMDS} ${UTR_PATH}
    # tools from build/out/
    rm -fr ${UTR_PTOOLS}
    cp -fr ${UTB_POUT_TOOLS} ${UTR_PATH}
    return 0
}

# function of do tar for release
# $1 - add string for name.
# $? - 0-OK,1-ERROR.
function DoTarRelease() {
    CurTime=`date +%Y%m%d-%H%M%S`
    ReleasePkg=unitest_${BuildArch}_${CurTime}.tar.gz
    echo "[TA] ${ReleasePkg}"
    tar -zcf ${UTB_PATH}/${UTB_DOUTPUT}/${ReleasePkg} -C ${UTB_PATH}/${UTB_DOUTPUT} release
    if [ -f ${UTB_PATH}/${UTB_DOUTPUT}/${ReleasePkg} ]; then
        ReleaseSize=`ls -lh ${UTB_PATH}/${UTB_DOUTPUT}/${ReleasePkg} |awk '{print $5}'`B
        echoI "${ReleaseSize} in ${UTB_PATH}/${UTB_DOUTPUT}"
        return 0
    else
        echoE "tar error"
        return 1
    fi
}

# function of do tar for small.
# $? - 0-OK,1-ERROR.
function DoTarSmall() {
    # strip all commands.
    ${CROSS_COMPILE}strip ${UTR_PCMDS}/*
    # strip all tools' bin sbin lib.
    BinDirs=`find ${UTR_PTOOLS} -maxdepth 2 -type d -name "bin" -or -name "sbin" -or -name "lib" |grep -v "ltp"`
    for BinDir in ${BinDirs}; do
        find ${BinDir} -type f |xargs ${CROSS_COMPILE}strip
    done
    # delete tools' man share include.
    find ${UTR_PTOOLS} -name "man" -or -name "share" -or -name "include" |xargs rm -fr
    # tar the release.
    DoTarRelease small
    return $?
}

# function of do tar for all.
# $? - 0-OK,1-ERROR.
function DoTarAll() {
    DoTarRelease all
    return $?
}

# function of show help.
# $1 - shell name.
function ShowHelp() {
    echo "./$1 [arch/d/c/m/n/i/a/A/r/R/b/B/t/T/q/Q/h] [opt/targets]"
    echo "    [arch] [opt]   - call arch with opt(h for help)"
    echo "    [d] [targets]  - build opt: down source repo"
    echo "    [c] [targets]  - build opt: configure"
    echo "    [m] [targets]  - build opt: make"
    echo "    [n] [targets]  - build opt: make clean"
    echo "    [i] [targets]  - build opt: make install"
    echo "    [a] [targets]  - build opt: as above dcmi"
    echo "    [A] [targets]  - build opt: as above dcnmi"
    echo "    [r]            - build opt: release with ln"
    echo "    [R]            - build opt: release with cp"
    echo "    [b] [targets]  - build opt: as above Ar"
    echo "    [B] [targets]  - build opt: as above AR"
    echo "    [t]            - build opt: tar release small"
    echo "    [T]            - build opt: tar release all"
    echo "    [q]            - build env: quiet warnning and error"
    echo "    [Q]            - build env: quiet all"
    echo "    [h/help]       - show this help doc"
    echo "    null           - default: B all"
    echo "    [targets] tools: ${ToolList}"
    echo "    [targets] commands : ${CmdsList}"
    return 0
}

# pre build for unit tool.
DoOpts=
DoTargets=
if [ $# -ge 1 ] ; then
    if [ $# -ge 2 ] ; then
        DoTargets=`echo $@ |sed -e 's/[^ ]* //'`
    fi
	if [ "$1" == "--help" ] || [ "$1" == "-h" ] ||
        [ "$1" == "help" ] || [ "$1" == "h" ]; then
        ShowHelp `basename $0`
		exit 0
    elif [ "$1" == "arch" ]; then
        ArchExec ${DoTargets}
        exit 0
    else
        DoOpts="$1"
        if [[ "${DoOpts}" =~ "a" ]]; then
            DoOpts=${DoOpts//a/dcmi}
        fi
        if [[ "${DoOpts}" =~ "A" ]]; then
            DoOpts=${DoOpts//A/ndcmi}
        fi
        if [[ "${DoOpts}" =~ "r" ]]; then
            BuildResMode=1
            DoOpts=${DoOpts//r/}
        fi
        if [[ "${DoOpts}" =~ "R" ]]; then
            BuildResMode=2
            DoOpts=${DoOpts//R/}
        fi
        if [[ "${DoOpts}" =~ "b" ]]; then
            BuildResMode=1
            DoOpts=${DoOpts//b/dcnmi}
        fi
        if [[ "${DoOpts}" =~ "B" ]]; then
            BuildResMode=2
            DoOpts=${DoOpts//B/dcnmi}
        fi
        if [[ "${DoOpts}" =~ "t" ]]; then
            BuildTarMode=1
            DoOpts=${DoOpts//t/}
        fi
        if [[ "${DoOpts}" =~ "T" ]]; then
            BuildTarMode=2
            DoOpts=${DoOpts//T/}
        fi
        if [[ "${DoOpts}" =~ "q" ]]; then
            BuildQuiet=1
            DoOpts=${DoOpts//q/}
        fi
        if [[ "${DoOpts}" =~ "Q" ]]; then
            BuildQuiet=2
            DoOpts=${DoOpts//Q/}
        fi
        if [ -z "${DoTargets}" ]; then
            DoTargets="${ToolList} ${CmdsList}"
        else
            ToolsAll=`echo ${DoTargets} |sed -e 's/ /\n/g' |grep -x tools`
            if [ ! -z "${ToolsAll}" ]; then
                DoTargets=`echo ${DoTargets} |sed -e "s/tools/${ToolList}/g"`
            fi
            CmdsAll=`echo ${DoTargets} |sed -e 's/ /\n/g' |grep -x commands`
            if [ ! -z "${CmdsAll}" ]; then
                DoTargets=`echo ${DoTargets} |sed -e "s/commands/${CmdsList}/g"`
            fi
            TargetsAll=`echo ${DoTargets} |sed -e 's/ /\n/g' |grep -x all`
            if [ ! -z "${TargetsAll}" ]; then
                DoTargets=`echo ${DoTargets} |sed -e "s/all/${ToolList} ${CmdsList}/g"`
            fi
        fi
	fi
else
    BuildResMode=2
    BuildTarMode=2
    DoOpts="cnmi"
    DoTargets="${ToolList} ${CmdsList}"
fi

# check build opt and targets.
DoTargets=`echo ${DoTargets} |sed -e 's/ /\n/g'|awk ' !x[$0]++' |sed -e 's/\n/ /g'`
if [ ${BuildResMode} -eq 0 ] && [ ${BuildTarMode} -eq 0 ] && \
    ([ -z "${DoOpts}" ] || [ -z "${DoTargets}" ]); then
    echoE "build opt or targets error"
    ShowHelp `basename $0`
    exit 0
fi

# show build evn first.
if [ ! -z ${DoOpts} ]; then
    echo "------------------------------"
    echo "arch-s: ${BuildArch}"
    if [ ! -z "${CROSS_IS}" ]; then
        echo "corss : yes"
        echo "arch    ---> ${CROSS_ARCH}"
        echo "gcc     ---> ${CROSS_COMPILE}gcc"
        echo "kern    ---> ${CROSS_LINUX_DIR}"
    else
        echo "corss : no"
    fi
    echo "opts  : ${DoOpts}"
    echo "target: "${DoTargets}
    echo "------------------------------"
fi

# check cross config and compiler-gcc.
if [ ! -z ${DoOpts} ]; then
    if [ ! -z "${CROSS_IS}" ]; then
        if [ -z "${CROSS_COMPILE}" ] || [ -z "${CROSS_ARCH}" ]; then
            echo "please config CROSS_COMPILE and CROSS_ARCH for cross"
            exit 1
        fi
        if [ -z "${CROSS_COMPILE_HOST}" ]; then
            CROSS_COMPILE_HOST=${CROSS_COMPILE%?}
        fi
    fi
    if ! type ${CROSS_COMPILE}gcc >/dev/null 2>&1; then
        echo "${CROSS_COMPILE}gcc not found"
        exit 1
    fi
fi

# do build for tools or commands.
if [ ! -z ${DoOpts} ]; then
    DoBuild "${DoOpts}" "${DoTargets}"
    if [ $? -gt 0 ]; then
        exit 1
    fi
fi

# do release after build.
if [ ${BuildResMode} -gt 0 ]; then
    if [ ${BuildResMode} -gt 1 ]; then
        DoReleaseCp
    else
        DoReleaseLn
    fi
    if [ $? -gt 0 ]; then
        exit 1
    fi
fi

# do tar after release.
if [ ${BuildTarMode} -gt 0 ]; then
    if [ ! -e ${UTR_PTOOLS} ] || [ -h ${UTR_PTOOLS} ]; then
        echoE "build R first before t/T"
        exit 1
    fi
    if [ ${BuildTarMode} -gt 1 ]; then
        DoTarAll
    else
        DoTarSmall
    fi
    exit $?
fi

exit 0
