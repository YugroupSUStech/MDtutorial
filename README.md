# MDtutorial
This tutorial is available to Yu group new members

此教程主要参考AMBER官方教程和Jerkwin的博客改写。在学习过程中若出现错误可先去以上教程中查看有无提示，如果没有可以将错误信息用google搜索，结合着amber19的[manual](https://github.com/YugroupSUStech/MDtutorial/blob/main/Amber19.pdf)解决。这里推荐几个学习MD和DFT的网站，遇到问题可以逛逛：

1. [Amber Tutorials](https://ambermd.org/tutorials/)
2. [哲科文Jerkwin](http://jerkwin.github.io/)
3. [思想家公社的门口](http://sobereva.com/)
4. [Amber-hub](https://amberhub.chpc.utah.edu/)

# 一、模拟前的准备工作
## 1.1 构建模型
这里有一张图是关于Amber的整个流程，可以了解一下：

![image](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/amberflow.png)

首先从蛋白质数据库中下载需要的PDB文件，(https://www.rcsb.org/) 网站中可以看到蛋白的一些信息，例如是否含有突变位点等。下载后的PDB文件需要检查其序列的完整性，这是因为在MD中的输入文件默认不同链间用*TER*分隔开，没有*TER*则认为相邻原子连接在一起。若有缺失序列需要首先进行同源模建：

### 同源模建
&emsp;关于同源模建的方法有很多，主要基于MSA（多序列比对），也可使用蛋白质预测在线服务器如trRosetta2.0, (https://yanglab.nankai.edu.cn/trRosetta/) ，在指定位置输入蛋白的序列，序列可以从pdb库中获得，如下图所示：

![image2](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/trrosetta.png)

等待几小时后可以得到预测的结构，一般的*TM-score*>0.5，结果可靠，分数最高的**model1**可以作为最后结果。

![image3](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/trrosetta2.png)

&emsp;另外也可以使**Swiss-model**进行建模，也非常简便，步骤与上述类似，详细网址：(https://swissmodel.expasy.org/) **Swiss-model**建模简单方便，可靠性高，但是它不能进行多模板建模。

## 1.2 处理pdb文件
这就要用到上面介绍的*pdb4amber*命令，在使用前可以用
```bash
$ pdb4amber -h
```
来查看此命令的用法， 下载的pdb文件可能包含一些非标准残基和配体或者辅因子，为方便后面预测残基的质子化状态我们可以先用*pdb4amber*去除这些残基，
```bash
$ pdb4amber -i input.pdb -o output.pdb -d -y 
```
其中，**-d** 表示 删掉所有水分子， **-y** 表示删掉所有氢原子，此命令除了输出**output.pdb** 还会将非标准残基输出到**xxx_nonstand.pdb**中。另外也会对所有的残基重新从1开始编号，使文件格式更标准。

## 1.3 预测质子化状态
用X-ray方法解析的蛋白质不含氢，因为无法解析得到它们。 LEaP程序会依据标准质子化状态，根据最佳氢键位置向这些残基自动添加氢原子。因此，如果不对重要的残基重命名，具有非标准质子化状态的氨基酸将被错误地质子化。例如，在 Asp 蛋白酶中，ASP并不一定是非质子化的（带负电），为了防止这种情况，必须将非标准ASP重命名为ASH（质子化的Asp，不带电）。使用正确的残基名，LEaP 将正确地为残基添加氢，下表显示了一些常见质子化状态的重命名。

![image4](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/proton.png)

下面介绍用**H++ server**来预测质子化状态：(http://newbiophysics.cs.vt.edu/H++/)

点击“process file”，将处理后的pdb文件上传，

![image5](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/pka1.png)

选择合适的pH，一般将pH设置为7.0，然后点击“process”提交任务，等待几十分钟可以看到结果。

![image6](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/pka2.png)

计算结束后可以看到每个残基的pKa，一般的pKa>7，残基质子化，<7残基溶剂化，重点关注HIS和CYS的质子化状态，另外这只是在生理环境下预测的质子化状态，尤其是HIS的三种状态要结合其他信息如反应机理等综合分析，（如果不清楚HIS的三种状态，可以百度一下）。对于CYS要看结构中有无二硫键。只需要下载下面几个关键的结果：

![image7](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/pka3.png)

使用`ambpdb`生成修改残基名称后的pdb文件，若预测的HIS等的质子化与机理不一致，可以手动在pdb文件中修改，如将HIE-->HIP。
```bash
$ ambpdb -p 0.15_80_10_pH7.0xxx.top -c 0.15_80_10_pH7.0xxx.crd > protein_H++.pdb
```
到这里，如果蛋白不包含非标准的残基，那其pdb文件基本就处理好了，最后的文件不包括CONNECT等原子间的连接信息，只需要每个原子的三维坐标即可。关于pdb的格式如下图所示，第2列为原子序号，第三列为原子类型，第四列为残基名称，第五列为残基编号，（若蛋白为多链，第五列对应链编号），第6-8列为原子坐标，第9列为occupancy，占有率，一般设置为1，第10列为温度因子，可设置为0，最后一列为元素名称。在导入leap程序中的输入文件，第9，10列可以不需要。[PDB文件格式说明](https://blog.sciencenet.cn/blog-548663-895916.html)

![image8](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/pdb1.png)

## 1.x 对蛋白封端

模拟多肽或者氨基酸数目较少的蛋白如需在模拟前封端，可以使用pymol操作，操作非常简便，如图首先点击右上角的“**Builder**”，在弹出的窗口中选择“**Protein**”，再点击 “**ACE**”cap在蛋白***N端***，再点击“**NME**” or “**NHH**”cap在蛋白***C端***。

![fengduan](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/fengduan.png)

## 1.4 非标准残基力场的构建

这里由琮晟写。

## 1.5 构建小分子力场

对于蛋白复合物中的配体和想研究的有机分子，由于他们的结构多样，不像氨基酸的分子构型是确定的，因此需要在模拟前自己构建特定的分子力场。一般在生物体系中对小分子计算其RESP电荷，这是由Kollman等人与1994年发展的方法，非常适用于蛋白，核酸以及有机分子在溶剂相等的模拟，文章链接：1. [A Second Generation Force Field for the Simulation of
Proteins, Nucleic Acids, and Organic Molecules](https://pubs.acs.org/doi/10.1021/ja00124a002) 。但是并不一定使用RESP电荷，一种基于半经验方法的AM1-bcc同样也可以使用，视自己的体系决定，这个在amber官网有详细的教程：2. [计算AM1-bcc电荷](https://ambermd.org/tutorials/basic/tutorial4b/index.php) 。下面介绍一下用gaussian和antechamber来拟合小分子RESP电荷的方法。

&emsp;首先，在计算电荷之前我们也需要知道小分子在`pH=7.0/7.4`的质子化状态，有时候N等原子的质子化对于小分子与蛋白的结合至关重要，这里介绍一下使用*propka3.0*来预测的方法。

* 安装propka
propka需要python 3.6 及以后的版本，可以通过anaconda创建环境然后用pip安装：
```
$ pip install propka
```
* 用propka预测
用法非常简单，只需要准备小分子的pdb文件。可以用命令行，也可以手动复制粘贴，比如从复合物为6ix5的pdb中取出残基名为BOO的配体：
```
$ awk '$1=="HETATM"' 6ix5.pdb | awk '$4=="BOO"' > BOO.pdb
```
然后使用propka预测：
```
$ propka3 BOO.pdb
```
or
```
$ python -m propka BOO.pdb
```
计算完成后，打开名为BOO.pka的文件，找到*SUMMARY OF PREDICTION*，若发现有极性原子的pKa>7，则该原子应为质子化的，体系电荷应+1。

![image9](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/propka1.png)

* 使用gaussian和antechamber拟合RESP电荷过程

将小分子加上合适的氢原子，可以使用*reduce*命令，和gaussview，或者openbabel等许多方法，注意N等极性原子的质子化！！！使用gaussian和antechamber拟合RESP电荷的过程大致分为两步：首先通过gaussian计算得到esp电荷，然后使用antechamber拟合resp电荷. 这里在网上有非常详细的教程：3. [使用gaussian和antechamber拟合RESP电荷](http://t.zoukankan.com/jszd-p-14163254.html) 。

&emsp;（1）使用gaussian优化结构，关键词如下：(一定注意小分子的电荷和spin要设置正确！！！)
```
#p HF/6-31G* SCF Pop=MK iop(6/33=2,6/42=6,6/50=1) opt
```
可以使用别的泛函如B3LYP等。

&emsp;（2）并在坐标后面输入两个文件名BOO_ini.gesp和BOO.gesp，（前者为初始结构的RESP电荷，后者为优化后的RESP电荷）。需要注意的是，BOO_ini.gesp 需要在坐标末尾空一行填入，BOO.gesp 同样与ini.gesp空一行，输入文件末尾空一行。

&emsp;（3）使用antechamber拟合resp电荷

    $ antechamber -i BOO.gesp -fi gesp -o BOO.mol2 -fo mol2 -pf y -rn LIG -c resp 

若在高斯优化没有生成gesp文件，可能是高斯版本的问题，请看上面的教程链接。其中，**-pf** 表示删除计算的临时文件，**y** 表示yes， **-rn** 表示将mol2文件中小分子残基名重命名为LIG， **-c** 指定原子电荷为resp。

&emsp;（4）使用`parmchk2`来生成*BOO_resp.frcmod*文件，这是一个参数文件，主要是生成的小分子mol2文件在通用力场**GAFF**中缺失的键长，键角，二面角等参数。
```
$ parmchk2 -i BOO.mol2 -f mol2 -i BOO_resp.frcmod
```
*BOO_resp.frcmod*将包含所有缺少的参数，或者通过类比类似的参数来填补这些缺失的参数。You should check these parameters carefully before running a simulation. If antechamber can't empirically calculate a value or has no analogy it will either add a default value that it thinks is reasonable or alternatively insert a place holder (with zeros everywhere) and the comment "ATTN: needs revision". In this case you will have to manually parameterise this yourself. 

至此，小分子的力场就构建完成，*BOO.mol2* 和 *BOO_resp.frcmod*包含了小分子的电荷，原子类型，残基名，键长，键角，二面角等信息，在后续的LEaP程序加载复合物pdb时将用到。但应注意的是，用*tleap*加载时，pdb中小分子的原子类型一定要和mol2文件中严格一致。

***对于含有金属配位的蛋白体系，例如血红蛋白酶P450中铁卟啉分子力场的构建，可使用MCPB.py构建，具体参考教程[Building Bonded Model for A HEME Group with MCPB.py](https://ambermd.org/tutorials/advanced/tutorial20/mcpbpy_heme.php)，写的非常详细！***

## 1.6 计算显式水系统中的盐摩尔浓度

为模拟正常的生理条件，需要为 MD 模拟正确设置离子浓度。细胞中 NaCl 的浓度约为 150 mM，因此我们需计算蛋白质系统中该浓度所需的钠离子和氯离子数目。这部分怎样计算在amber官网的教程中有详细过程，[Calculating Salt Molarity in an Explicit Water System](https://ambermd.org/tutorials/basic/tutorial8/index.php)，如下图所示。

![image10](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/calcc.png)

这里以6ix5为例计算构建`distance=10`的溶剂盒子所需要的Na+和Cl-个数，用`tleap -i tleap.in`载入下述tleap.in输入文件：
```
source leaprc.protein.ff14SB
source leaprc.water.tip3p
source leaprc.gaff2
pdb = loadpdb 6ix5_noH.pdb
solvateBox pdb TIP3PBOX 10.0
quit
```
打开`tleap.log`的输出文件，可以找到溶剂盒子的体积，下图所示。这里介绍一个计算浓度的简便算法，用自己体系的盒子体积除以上面图片中的体积再乘以18.8即为所需的离子数目：*767021/208141x18.8=69* ， 所以最后的溶剂盒子需要69个Na+ 和 Cl-。

![image11](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/calcc2.png)

至此，运行MD前的准备工作基本完成，下面我们介绍MD的模拟步骤。

# 二、MD模拟步骤

## 2.1.1 tleap加载蛋白复合物

LEaP程序有GUI界面的xleap也有命令行的tleap，我们这里介绍命令行界面tleap的用法，关于LEaP的介绍可查看[Fundamentals of LEaP](https://ambermd.org/tutorials/pengfei/index.php)。这里以*6ix5_SAM_ambiTS_noH.pdb*为例作为蛋白复合物，其中包含了*SAM*辅因子和*BOO*小分子配体，用`tleap -i tleap.in`载入下述tleap.in输入文件：
```
source leaprc.ff14SB
source leaprc.water.tip3p
source leaprc.phosaa10  ## 磷酸化残基力场 
loadamberparams frcmod.ions1lm_126_tip3p    ## TIP3P水与1价电荷互作的力场，可以不写，因为已包含在leaprc.water.tip3p中
source leaprc.gaff
loadamberparams TS-1_resp.frcmod 
loadamberparams SAM_resp.frcmod 
SAM = loadmol2 SAM_resp.mol2
BOO = loadmol2 BOO_resp.mol2
mol = loadpdb 6ix5_SAM_ambiTS_noH.pdb
solvateBox mol TIP3PBOX 10.0
addions mol Na+ 0
addions mol Cl- 0
addions mol Na+ 70
addions mol Cl- 70
savepdb mol 6ix5_complex_solv.pdb  
saveamberparm mol min.prmtop min.inpcrd
```
为了运行分子动力学模拟, 我们需要加载力场来描述复合物的势能. 对蛋白质一般使用AMBER的*FF14SB*力场, *FF14SB*基于*FF12SB*, *FF12SB*是*FF99SB*的更新版本, 而*FF99SB*力场又是基于原始的Amber的Cornell等人(1995)的*ff94*力场。*FF14SB*力场最显著的变化包括更新了蛋白质*Phi-Psi*的扭转项, 并重新拟合了侧链的扭转项. 这些变化一起改进了对这些分子中α螺旋的估计。

`source`命令用于加载力场，*leaprc.water.tip3p*为*TIP3P*水盒子模型的力场，*phosaa10*表示磷酸化修饰氨基酸的力场，*ions1lm_126_tip3p*表示tip3p水中+1，-1离子的参数。

`solvatebox`命令对系统进行溶剂化。

`addions mol Na+ 0`命令使用counter ions 对体系电荷进行平衡，`addions mol Na+/Cl- 70`添加盐离子至0.15 mM。

`saveamberparm`保存溶剂化之后体系的拓扑文件（prmtop）和坐标文件（inpcrd）。

小分子和辅因子的mol2文件和frcmod见文件夹[/parm](https://github.com/YugroupSUStech/MDtutorial/tree/main/parm)，这里需要注意复合物pdb中配体的原子顺序与mol2文件的可以不一致，但原子类型要和mol2文件中要严格一致！！！

退出tleap请用`quit`。如果在载入蛋白时报错，一定先查看`tleap.log`文件，看看是哪一步出错，一般在载入小分子时出错很多，如果出现以下错误，很有可能是pdb文件中小分子的原子类型错误，与构建的mol2等力场文件不一致，或者残基名与mol2文件不一致，请仔细检查。其他错误可以将报错信息用google搜索。（不建议百度）
```
FATAL: Atom XXX does not have a type
```

## 2.1.1 氢质量重排

在需要进行长时间的MD模拟中，可以使用`parmed`来对拓扑文件进行氢原子质量重排处理，以便于使用更长的timestep（比如4fs）进行长时间的MD模拟。

```
$parmed min.prmtop
```
在交互式界面中输入如下：
```
HMassREpartition
parmout min_hmr.prmtop
go
```
在后续的模拟中使用`min_hmr.prmtop`即可采用更大的时间步长进行长时间模拟。

## 2.2 能量最小化

在得到参数和拓扑文件`prmtop`以及坐标文件`inpcrd`后，我们用`sander`进行体系能量的最小化，也可以使用Amber的另外一个高性能版本`pmemd`。进行能量最小化有许多种选择，我们这里首先对蛋白复合物进行固定以优化水分子和离子，然后再将复合物放开优化整个系统。对应的`min1.in`和`min2.in`如下：

* min1.in
```
minimizes solvent molecules
 &cntrl
  imin   = 1,
  maxcyc = 10000,
  ncyc   = 20000,
  ntb    = 1,             
  ntr    = 1,            
  cut    = 10.0
  restraint_wt = 200.0,
  restraintmask = ':1-391',
 /
```

* min2.in
```
minimizes all molecules
 &cntrl
  imin   = 1,
  maxcyc = 10000,
  ncyc   = 20000,
  ntb    = 1,             
  ntr    = 0,            
  cut    = 10.0
 /
```
这些设置总结如下：

* imin=1: 选择运行能量最小化
* maxcyc=2000: 最小化的最大循环数
* ncyc=1000: 最初的0到ncyc循环使用最速下降算法, 此后的ncyc到maxcyc循环切换到共轭梯度算法（这里表明只使用最速下降法优化10000个循环）
* ntb=1: 等容的周期性边界
* ntr=1：使用谐波势限制笛卡尔空间中的特定原子的标志，如果`ntr>0`，则启用限制。受约束的原子是由`restraintmask`决定的。关于Amber里约束原子的规则，请查看[Amber里关于ambmask总结](https://blog.sciencenet.cn/blog-3366368-1080067.html)
* cut=10.0 以埃为单位的非键截断距离(对于PME而言, 表示直接空间加和的截断. 不要使用低于8.0的值. 较高的数字略微提高精度, 但是大大增加计算成本)

使用`sander`命令执行最小化，（可以在太乙上使用`sander.MPI`多核并行计算，节约时间）。另外注意在使用`ntr=1`时，执行sander程序应在命令行加上`-ref min.inpcrd`用来指定所施加的限制的参考坐标！
```bash
$ mpirun -np 40 sander.MPI -O -i min.in -o min.out -p min.prmtop -c min.inpcrd -r min.nrst
```

## 2.3 加热升温
接下来将系统在**NVT**系综下分6次，每次50 K，逐渐升温至300 K，加热350 ps：
* heat.in
```
heating under NVT 
 &cntrl
  imin   = 0,
  ig     = -1,  
  irest  = 0,  
  ntx    = 1,   
  ntb    = 1,   
  cut    = 10.0,
  ntr    = 0,   
  ntc    = 2,   
  ntf    = 2,   
  ntxo   = 2,   
  tempi  = 0.0,
  temp0  = 300.0,
  ntt    = 3,
  nmropt = 1,
  gamma_ln = 1.0,    
  nstlim = 175000, dt = 0.002,                     
  ntpr = 1000, ntwr = 1000, 
 /
 
&wt type  = 'TEMP0', istep1=0, istep2=25000, value1=0.0, value2=50.0 /
&wt type  = 'TEMP0', istep1=25001, istep2=50000, value1=50.0, value2=100.0 / 
&wt type  = 'TEMP0', istep1=50001, istep2=75000, value1=100.0, value2=150.0 / 
&wt type  = 'TEMP0', istep1=75001, istep2=100000, value1=150.0, value2=200.0 / 
&wt type  = 'TEMP0', istep1=100001, istep2=125000, value1=200.0, value2=250.0 / 
&wt type  = 'TEMP0', istep1=125001, istep2=150000, value1=250.0, value2=300.0 /
&wt type  = 'TEMP0', istep1=150001, istep2=175000, value1=300.0, value2=300.0 /
&wt type  = 'END' /
```
这些设置总结如下：

* imin=0: 选择运行分子动力学(无最小化)
* ig=-1: 随机化伪随机数发生器的种子
* irest=0: 不重新启动模拟(不适用于最小化)
* ntx=1: 从ASCII格式的inpcrd坐标文件读取坐标, 但不读取速度
* ntc=2: 启用SHAKE来约束所有包含氢的键
* ntf=2: 不计算受SHAKE约束的键所受的力
* ntxo=2 写入轨迹的最终坐标、速度和盒子大小的格式。`=1` ACSII格式，`=2` defult, NetCDF格式
* tempi=0.0: 初始恒温器的温度
* temp0=300.0: 最终恒温器的温度
* ntt=3: 使用Langevin恒温器控制温度
* gamma_ln=1.0: Langevin恒温器的碰撞频率 （请查看amber手册，以选择合适的温度解耦器和碰撞频率）
* nstlim=175000: 要运行的MD步数（运行时间长度，单位 ps；dt=0.002 时间步长，ps）
* &wt type=xxx：分6次加热，每次50 K
* ntpr=1000: 每ntpr次循环写入Amber mdout输出文件一次
* ntwr=1000: 每ntwr次循环，输出一次 “restrt” 文件
* ntwx=0：每ntwx次输出一次轨迹，这里不输出

使用`pmemd.cuda_SPFP`进行加热，也可以使用sander，但前者更快。
```
$ CUDA_VISIBLE_DEVICES=0 pmemd.cuda_SPFP -O -i heat.in -o heat.out -p min.prmtop -c min.nrst -r heat.nrst
```

## 2.3 平衡体系

在用水盒子溶剂化蛋白复合物之后，体系的密度一般在0.8~0.9 g/cc，而正常情况下的盐溶液密度应为1.1 g/cc，因此我们在平衡阶段应首先使用恒温恒压 **NPT** 模拟来平衡体系的密度，在密度稳定之后可以转向NVT系综再预平衡一段时间，或者直接开始生产MD。对于不同科学问题的MD模拟，平衡和生产MD阶段所用的系综可以不同，对于研究蛋白质折叠等动力学问题，应使用 **NPT** 系综，而研究生物大分子与小分子结合，计算结合自由能等热力学性质，使用 **NVT** 系综就已足够。具体可查看[常规平衡态分子动力学模拟](https://zhuanlan.zhihu.com/p/345627471)。

这里我们现在 **NPT** 系综下平衡至密度稳定，再转向 **NVT** 系综下平衡：
* equil1.in
```
equil in NPT ensemble
 &cntrl
  imin   = 0,
  ig     = -1,
  irest  = 1,
  ntx    = 5,
  ntb    = 2,
  pres0  = 1.0,
  ntp    = 1,
  taup   = 2.0,
  cut    = 10.0,
  ntr    = 0,
  nmropt = 0,
  ntc    = 2,
  ntf    = 2,
  ntxo   = 2,
  tempi  = 300.0,
  temp0  = 300.0,
  ntt    = 3,
  gamma_ln = 2.0,
  nstlim = 100000, dt = 0.002,
  ntpr = 1000, ntwx = 1000, ntwr = 1000,
 /
```
* equil2.in
```
equil in NVT ensemble
 &cntrl
  imin   = 0,
  ig     = -1,
  irest  = 1,
  ntx    = 5,
  ntb    = 1,
  pres0  = 1.0,
  ntp    = 0,
  taup   = 2.0,
  cut    = 10.0,
  ntr    = 0,
  nmropt = 0,
  ntc    = 2,
  ntf    = 2,
  ntxo   = 2,
  tempi  = 300.0,
  temp0  = 300.0,
  ntt    = 3,
  gamma_ln = 2.0,
  nstlim = 100000, dt = 0.002,
  ntpr = 1000, ntwx = 1000, ntwr = 1000,
 /
```
这些设置总结如下：

* ntx=5：从NetCDF或ASCII格式的inpcrd坐标文件读取坐标和速度
* ntb=2：在恒定压力下使用周期性边界条件
* ntb=1：在恒定体积下使用周期性边界条件
* ntp=1：使用Berendsen恒压器进行恒压模拟
* pres0=1：参考压力，in units of bars，1 bar大约0.987 atm
* taup=2：压力弛豫时间，推荐1~5

使用`pmemd.cuda_SPFP`进行平衡：
```
$ CUDA_VISIBLE_DEVICES=0 pmemd.cuda_SPFP -O -i equil.in -o equil.out -p min.prmtop -c heat.nrst -r equil.nrst -x equil.mdcrd
```
在进行第一步平衡时可以使用`tail -f equil1.out` 监控作业的状态，查看体系的密度是否稳定，下图所示：

![image12](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/equil1.png)

## 2.4 生产MD模拟

与平衡阶段类似，只需要将模拟时间延长，我们以模拟600 ns为例。需要注意的是，在**NPT**系综下模拟太长时间容易导致体系的崩溃，可以将长时间的模拟分成几段；而在**NVT**系综下不会出现这种情况，为了方便我们将600 ns的模拟分成15段：
```bash
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
do
j=$[i-1]
mkdir produc_$i
cp produc_$j/Production_$j.nrst  ./produc_$i
cp min.prmtop  ./produc_$i
cd produc_$i

/bin/cat > Production.in<<EOF
Production simulation
 &cntrl
  imin   = 0,
  ig     = -1,
  irest  = 1,
  ntx    = 5,
  ntb    = 1,
  pres0  = 1.0,
  ntp    = 0,
  cut    = 10.0,
  ntr    = 0,
  ntc    = 2,
  ntf    = 2,
  nmropt = 0,
  ntxo   = 2,
  tempi  = 300.0,
  temp0  = 300.0,
  ntt    = 3,
  gamma_ln = 2.0,
  nstlim = 20000000, dt = 0.002,
  ntpr = 25000, ntwx = 25000, ntwr = 50000,
 /

EOF
done
```
整个MD过程的脚本见[/parm](https://github.com/YugroupSUStech/MDtutorial/tree/main/parm)中的***run_md.sh***。

## 2.5 限制性模拟

对于限制性模拟（restrained MD），大致有两种常见情况，一种是对蛋白或配体的某几个键长进行约束，例如对有氢键相互作用的原子或者过渡态中要成键断键的原子约束在一定距离内；另外一种情况是将某些原子的笛卡尔坐标施加谐波势进行固定。对于第一种情况，需要对关键词`nmropt`设为1，同时用指定文件`rst.dist`来描述如何对其进行限制，可以参考教程[Generating NMR restraints](https://ambermd.org/tutorials/advanced/tutorial4/index.php)中的约束键长部分，另外教程中也讲解了如何对torsion angle进行约束。

* nmropt_md.in
```
restrain Production simulation
 &cntrl
  imin   = 0,
  ig     = -1,
  irest  = 1,
  ntx    = 5,
  ntb    = 1,
  pres0  = 1.0,
  ntp    = 0,
  cut    = 10.0,
  ntr    = 0,
  ntc    = 2,
  ntf    = 2,
  nmropt = 1,  ###notice the value is 1
  ntxo   = 2,
  tempi  = 300.0,
  temp0  = 300.0,
  ntt    = 3,
  gamma_ln = 2.0,
  nstlim = 20000000, dt = 0.002,
  ntpr = 25000, ntwx = 25000, ntwr = 50000,
 /
 
&wt 
 type   = 'END'
 /
 
LISTOUT = POUT
DISANG = ../rst.dist
```
* rst.dist 文件如下，对于atom id为6104和6105的成键原子对，施加谐波势使其约束在1.8~2.3 A范围内。对其上限施加100 kcal/mol·A 的谐波势，同时对其下限设为0。
```
&rst
  iat=  6104,  6105, r1= 1.30, r2= 1.80, r3= 2.30, r4= 2.80, rk2=0.0, rk3=100.0,
 &end
 
 &rst
  iat=  6099,  6100, r1= 1.30, r2= 1.80, r3= 2.90, r4= 3.40, rk2=0.0, rk3=100.0,
 &end
 
  &rst
  iat=  6088,  6102, r1= 1.30, r2= 1.80, r3= 2.50, r4= 3.00, rk2=0.0, rk3=100.0,
 &end
```
另外也可以对原子坐标施加谐波势能进行固定，此时需用关键词`ntr=1`，同时用`restrain_wt`指定所施加谐波势的大小，`restrainmask`指定对哪些原子进行固定，另外注意在使用`ntr=1`时，执行sander程序应在命令行加上`-ref min.inpcrd`用来指定所施加的限制的参考坐标！

* ntr_md.in
```
Production simulation NVT
 &cntrl
  imin   = 0,
  ig     = -1,
  irest  = 0,
  ntx    = 5,
  ntb    = 1,
  pres0  = 1.0,
  ntp    = 0,
  cut    = 10.0,
  ntr    = 1,
  nmropt = 0,  
  ntc    = 2,
  ntf    = 2,
  ntxo   = 2,
  restraint_wt = 10.0,
  restraintmask = ':390',  
  tempi  = 300.0,
  temp0  = 300.0,
  ntt    = 3,
  gamma_ln = 2.0,
  nstlim = 20000000, dt = 0.001,
  ntpr = 25000, ntwx = 25000, ntwr = 50000,
 /
```
在模拟过程中若出现cuda报显存错误等信息，很有可能是所施加的力太大同时使用了SHAKE算法，具体请查看[SHAKE failures](https://ambermd.org/Questions/blowup.html)中所描述的体系崩溃是否和你的体系一样，这里有关于体系**Blow Up**问题的中文解释[GROMACS术语：爆破(Blowing_Up)](https://blog.sciencenet.cn/blog-548663-1023974.html)。解决此类问题的方法，一是减小施加的限制力，而是缩短时间步长`dt=0.002`->`dt=0.001`，另外也要和上述教程说的，检查结构是否有原子重合。
```
$ pmemd.cuda_SPFP -O -i 04Production.in -o 04Production.out -p min.prmtop -c equil3.nrst -r 04Production.nrst -x 04Production.mdcrd  -ref equil3.nrst
```

# 三、分析轨迹
## 3.1 RMSD分析

这里我们介绍MD模拟后最常用的一种分析: 即坐标均方根偏差(RMSD)。RMSD是测量某部分特定原子相对于一参考结构的坐标偏差, 最完美的重合时则RMSD为0.0. RMSD定义为:

![rmsd](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/rmsd.png)

其中***N***是原子数，***mi***是原子***i***质量，***Xi***是目标原子***i***的坐标向量，***Yi***是参考原子***i***的坐标向量，***M***是总质量。如果 RMSD 不是质量加权的，则所有的***mi=1, M=N*** 。

在计算目标到参考结构的 RMSD 时，有两个非常重要的要求： 
* 目标中的原子数必须与参考中的原子数匹配。 
* 目标中原子的顺序必须与参考中的原子顺序相匹配。

在本例中，我们先将上述MD模拟后的几个片段使用`trans.in`合并为一整条轨迹，轨迹采用**NetCDF**格式，它比**ASCII**格式处理速度更快、更紧凑、精度更高。在转化过程中可以选择去除所有的水分子和离子，并使用`autoimage`将蛋白居中，便于后续观察。（关于autoimage：自动居中和成像（按分子）具有周期性边界的轨迹。在大多数情况下，仅指定“autoimage”就足够了。 “锚”分子（默认为第一个分子）将居中；只有当成像使它们更接近“锚”分子时，所有“固定”分子才会被成像； “固定”分子的默认值是所有非溶剂非离子分子。所有其他分子（称为“移动”）将自由成像。一般来说，“锚”分子应该是与所有“固定”分子距离最小的分子。）

* trans.in
```
parm ../min.prmtop
trajin ../produc_1/Production_1.mdcrd
trajin ../produc_2/Production_2.mdcrd
trajin ../produc_3/Production_3.mdcrd
trajin ../produc_4/Production_4.mdcrd
trajin ../produc_5/Production_5.mdcrd
trajin ../produc_6/Production_6.mdcrd
trajin ../produc_7/Production_7.mdcrd
trajin ../produc_8/Production_8.mdcrd
trajin ../produc_9/Production_9.mdcrd
trajin ../produc_10/Production_10.mdcrd
trajin ../produc_11/Production_11.mdcrd
trajin ../produc_12/Production_12.mdcrd
trajin ../produc_13/Production_13.mdcrd
trajin ../produc_14/Production_14.mdcrd
trajin ../produc_15/Production_15.mdcrd
strip :WAT,Na+,Cl-
trajout Production1-15.nc
autoimage
go
```
处理后的`Production1-15.nc`将只包含复合物分子坐标。另外，我们也可以准备一个相应的只包含蛋白复合物拓扑文件：
* parmtrans.in
```
parm min.prmtop
parmstrip :WAT,Na+,Cl-
parmwrite out min_noion_water.prmtop
go
```
接下来用CPPTRAJ进行RMSD计算，需要注意的是，计算RMSD需要指定对象，并且选定参考结构，可以详细参考教程[CPPTRAJ教程：RMSD分析](http://jerkwin.github.io/2018/03/15/AMBER_CPPTRAJ%E6%95%99%E7%A8%8BC1-RMSD%E5%88%86%E6%9E%90/)。本例中，我们选定模拟的起始点作为reference，只计算1-474号残基CA的波动，输入文件如下：
* rmsd.in
```
parm min_noion_water.prmtop
trajin Production1-15.nc
reference ../produc_1/Production_0.nrst
rmsd :1-474@CA out prodProteinRmsdCA.dat mass reference
run
exit
```
如若需要计算相对于平均结构的RMSD或者计算不同轨迹间的RMSD请详细查看以上教程。

## 3.2 使用CPPTRAJ进行主成分分析

正在学习中，可参考教程[Introduction to Principal Component Analysis](https://amberhub.chpc.utah.edu/introduction-to-principal-component-analysis/)

## 3.3 使用CPPTRAJ进行聚类分析

关于聚类分析有许多种统计分析方法，其中使用最多的是k-means算法，可参考教程[Clustering a protein from multiple independent copies](https://amberhub.chpc.utah.edu/clustering-a-protein-trajectory/)，写的非常详细！



