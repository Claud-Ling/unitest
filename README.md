# UnitTest测试 (使用者阅读)

## 环境说明

1. 功能描述

> * 管理unittest测试命令/脚本/用例运行环境
> * utest脚本统一unittest测试命令/脚本/用例的使用入口
> * 集成不同工具的调用并快速构建测试用例
> * 自动存储测试log

2. 文件列表

> * [build/](/build/)              -- 管理unittest工具/命令的编译及打包
> * [cases/](/cases/)             -- 测试用例集
> * [commands/](/commands/)   -- 测试命令集(自定义,可无)
> * [scripts/](/scripts/)           -- 测试脚本集(可封装测试调用)
> * [tools/](/tools/)              -- 测试工具集(开源,可无)
> * [utest](/utest)    	        -- 测试入口脚本
> * [README.md](/README.md)   -- 本说明文档

3. 环境要求

> * linux系统，安装有/bin/bash
> * 安装有命令: vim

4. 测试命令

> ```sh
> # 直接使用，通过用例/脚本/命令名及其参数调用:
> ./utest [-f] <case>
> ```

## 环境部署

在使用前，需要进行测试环境部署，

1. 在主机上进行编译

> ``` sh
> cd build
> ./build.sh
> ```

2. build/output目录下生成unittest_xxx.tar.gz，部署只需在待测试机上解压即可：

> ``` sh
> mkdir unittest
> tar -zxf unittest_xxx.tar.gz -C unittest
> ```

## 测试入口

本测试环境使用一个测试入口脚本`utest`完成所有测试相关操作，其有
2种运行模式。

1. 指定参数运行

该模式下每个参数通过-?指定：
> | 标志 | 参数    | 功能                          |
> | :--- | :------ | :---------------------------- |
> | -f   | case    | 添加用例(名/路径)到runcase    |
> | -c   | command | 添加命令及参数,带参数可用""   |
> | -v   | 无      | 显示更多我测试过程信息        |
> | -q   | 无      | 安静测试, 测试执行信息只存log |
> | -h   | 无      | 查看帮助                      |

示例:
> ``` sh
> # 安静模式下运行lmbench用例，log等输出到lmbench_out目录:
> ./utest -q -f lmbench -o lmbench_out
> ```

2. 非入口运行

除了上述使用`utest`入口脚本进行测试外，本环境内的命令/脚本都可直接
运行，只需进入其目录下运行即可，而开源工具则需进入工具子目录的相关
bin下(不推荐)，可使用封装好的脚本调用:

> | 类型 | 目录     | 运行                      |
> | :--- | :------- | :------------------------ |
> | 命令 | command/ | 直接运行: ./command paras |
> | 脚本 | script/  | 直接运行: ./script paras  |
> | 工具 | tools/   | 可无,可通过封装的脚本运行 |

示例:
> ``` sh
> # 直接mmt脚本调用memtester工具测试:
> cd scripts/
> ./mmt 10M 1
> ```

## 测试工具

1. 支持工具

本测试环境支持多种开源测试工具集成并供用例定制使用。  
所有支持的开源工具都有一个对应脚本封装在scripts/：  
> * lmbench      -- LMbench工具: 系统性能评测  
> * ltp          -- LTP测试项目工具: linux功能/性能压力测试 
> * iozone       -- iozone工具: 文件系统测试工具  (TODO)
> * iperf        -- iperf工具: 网络性能测试工具   (TODO)
> * mmt          -- memtester工具: 内存测试，坏位检测  (TODO)
> * sat          -- stressapptest工具: 内存流量压力测试  (TODO)

以上封装了开源工具的测试脚本可直接运行使用，也可被用例文件引用。 

2. 支持命令

自定义测试命令全位于commands/:
> * 暂无。

以上测试命令可直接运行使用，也可被用例文件引用。 

3. 测试脚本

自定义测试脚本全位于scripts/下:
> * 暂无。

以上测试脚本可直接运行使用，也可被用例文件引用。 

## 测试用例

1. 支持用例

本测试环境所有测试用例都是位于cases/下的1个文本文件，

使用./utest -h可以查看到当前支持的cases，目前默认支持的用例：

> * lmbench
>
> > 系统性能评测(反应时间和带宽)，使用LMbench工具测试。
>
> * memtest
> > 内存错误检查，使用memtester测试100M，10次。
>

PS: 可根据需求拷贝或编辑上述测试用例，以满足测试需求。

2. 用例文件

对于cases/下的用例文件，每行为一个用例执行，其格式如下：
> ```text
> # comments
> entry [paras]
> ```

其中entry即为commands/scripts目录对应的可执行文件名，如：lmbench, mmt等;  
而paras即为测试入口参数，即上述对应测试命令的参数。

3. 新增用例

测试用例实际为cases/下的1个文本文件，每行为1个测试命令/工具脚本的
调用，因此新增用例只需要在cases/下创建1个文本文件并将测试执行行加
入即可。

## 测试结果

所有测试结果都位于output指定的测试输出下的一个out-xxxx子目录内。 
对于不同工具的测试结果输出文件不同:  
> * lmbench
> > .summary.out  -- 多次测试的统计信息
> > .summary.errs -- 多次测试的错误信息
> > .summary.perc -- 多次测试的统计信息(百分比)
>
> * mmt(memtester)
> > log           -- 测试过程及结果log

PS: 在每个测试输出的out-xxxx子目录下，都会自动产生2个文件:
> run            -- 本次测试命令行(可在utest所在目录通过sh该run复现测试)  
> tc             -- 本次测试的.caserun副本(本次测试运行的用例)  
> log            -- 本次测试log(包括使用-q时未打印到屏幕的所有过程log)  
> rpt            -- 本次测试rpt(用例所有行的测试结果统计)  

# 测试环境构建 （维护开发者阅读）

## build环境说明

1. 功能描述

> * 管理unittest工具/命令的编译及安装构建
> * 支持不同架构目标，交叉编译只需进行CROSS配置
> * 支持unittest测试环境的部署及打包

2. 目录结构

> * [arch/](/arch/)         -- 编译目标架构配置
> * [down/](/down/)         -- wget方式下载的源码包(自动生成)
> * [rules/](/rules/)       -- 测试工具/命令编译规则
> * [output/](/output/)    	-- 测试工具/命令编译的打包输出
> * [build.sh](/build.sh)    	    -- 编译构建脚本

3. 环境要求

> * linux系统，安装有/bin/bash
> * 安装有命令: make, git, wget
> * 安装有编译工具: gcc, cross-gcc(根据arch不同)

## 构建命令

> ``` sh
> # 选择构建的架构目标(ce3226或者x86，根据提示输入索引号):
> ./build.sh x
> #自动完成所有工具的编译构建
> ./build.sh
> ```

## 目标架构

1. 架构配置

所有支持的目标架构都为arch/下一个文件，文件名即架构名。

目前支持的目标架构有:

> * ce3226    -- ce3226芯片目标: aarch64, 使用aarch64-linux-gnu-gcc
> * X64       -- X86_64目标: X86_64, 使用gcc(非交叉编译)

每个目标架构的编译配置文件，内有配置项有如下:

> * CROSS_IS           -- 是否交叉编译: y/空
> * CROSS_ARCH         -- 目标芯片架构名称，如: aarch64
> * CROSS_COMPILE      -- 交叉编译工具，如: aarch64-linux-gnu-
> * CROSS_COMPILE_HOST -- 交叉编译目标主机(可不配为默认)
> * CROSS_LINUX_DIR    -- 目标linux内核输出目录(部分工具可能需要)

对于ce3226目标架构，有[ce3226](/arch/ce3226)，可参考。

2. 新增架构

若要加入一种新架构xxx支持，只需在arch/下新建一个名为xxx的文件，
并在其内修改上述配置项，最后选择该xxx为当前架构目标，编译即可：

> ```sh
> # 新建架构目标:
> # 参考上述说明，配置好对应CROSS_XXX变量，保存.
> vi arch/xxx
> # 按上述构建命令，选择xxx为目标架构，并完成编译构建:
> ./build arch x
> ./build
> ```

PS: 述CROSS_COMPILE的配置若不带命令全路劲，请先将cross-gcc的
bin路劲加入PATH，否则将检测并报错。

3. 当前架构

所有的编译构建及测试都是基于当前目标架构的，当前目标架构即为软链接
文件arch/cross的链接目标架构，如当前架构为x2时:

> arch/cross -> ce3226

目标架构切换的本质就是对软链接文件arch/cross的链接目标的修改。

4. arch脚本

上述`./build arch x`命令，实际调用的是`./arch/arch x`，该`arch`
脚本提供目标架构选择切换等功能:

> ```sh
> # 配置使用默认架构(arch/下排序第一的架构目标):
> ./build arch d
> # 列出所有支持的目标架构:
> ./build arch l
> # 选择目标架构切换:
> ./build arch x
> # 显示当前目标架构名:
> ./build arch s
> # 通过索引快速切换，如索引号2:
> ./build arch 2
> # 查看帮助信息:
> ./build arch h
> # 可上述多个命令串用，如列出所有并选择切换:
> ./build arch lx
> ```

## 测试用例规则

1. 支持命令工具

所有支持的测试命令/工具目标的编译规则都位于rules/下：
目前支持的测试工具有(文件名即为目标工具名)：  

> * commands     -- 自定义测试工具(编译../commands下命令)  
> * lmbench      -- LMbench工具: 系统性能评测  

上述编译规则除commands外，都是开源工具的编译规则，其源码位于../tools,
其编译输出位于output/out/tools下，最终部署在../release/tools下。  
而commands则为所有自定义测试命令的编译规则，源码位于../commands,
其编译输出位于output/out/commands下，最终部署在../release/commands下。  

2. 新增开源工具

若要加入一种新开源工具xxx的支持，只需在rules/下新增一个名为xxx的规则脚本。
并根据需要在其内实现3个操作函数:

> xxx_env() -- 工具环境参数配置
>
> > **必须实现，指定工具源码及输出所在目录**  
> > 调用InRuleEnv传入工具相应参数即可:  
> > 类型/源码目录名/安装目录名/下载方式/下载URL/下载可选参数  
>
> xxx_conf() -- 进行编译前的配置
>
> > **不必须实现，未实现跳过该操作**  
> > 对于运行./configure配置的，调用InRuleConf传入工具相应参数即可():  
> > 配置脚本名称(configure)/补丁文件路径(如果有)/额外的配置参数  
>
> xxx_make() -- 进行编译make操作:
>
> > **不必须实现，未实现自动默认进入源码目录执行make**  
> > $@ - 会用到的make目标:空/clean/install  
> > 一般调用InRuleMake传入工具相应参数即可  

PS: 上述xxx_conf及xxx_make函数的执行环境都是在xxx_env所配置的工具源码目录
内，其将在`build.sh`脚本中根据需要调用，完成其函数目标并最终完成自动构建工作。

## 新增测测试用例

对于自定义的测试命令，其源码位于../commands下，且1个命令对应1个子目录，
要新增一个yyy命令，只需在../commands下新建一个yyy的子目录，并放置其源码
yyy.c(或其他yyy2.c/libyyy.so)，之后编译即可。

对于简单源码结构的命令无需构建Makefile，rules/commads内将自动扫描该子目录下
.c/.so文件，并直接通过gcc编译构建。

而对于结构较复杂的命令，可在命令子目录下构建Makefile，rules/commads内将自动
调用make命令构建，**但该Makefile有如下要求**:  

> * 编译使用(以支持不同架构): $(CROSS_COMPILE)gcc  
> * 默认目标为编译目标命令,并支持目标: clean/install  
> * install目标可通过变量指定安装命令目录: $(O)  

## 构建输出

所有测试命令/工具在自动构建后，都默认将被安装在output/out下，该output/out
为软链接文件(对于ce3226架构，指向实际输出output/out-ce3226)，其可根据当前架构选择
快速切换，测试命令安装于output/out/commands，测试工具安装于output/out/tools。

## 测试打包

上述的默认构建命令，会将测试工具命令/工具自动编译，并安装到../release下，该
目录即为测试运行目录，对于非交叉编译的x64架构，可直接进入该目录运行测试。

而对于交叉编译的目标，则需要通过nfs或其他方式部署到目标机上，`build.sh`命令提供
了参数t/T，可将cp部署(R)的../release目录进行打包，打包的.tar.gz文件将放置于
output/release下。