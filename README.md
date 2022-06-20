# MDtutorial
This tutorial is available to Yu group new members
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
pdb4amber -h
```
来查看此命令的用法， 下载的pdb文件可能包含一些非标准残基和配体或者辅因子，为方便后面预测残基的质子化状态我们可以先用*pdb4amber*去除这些残基，
```bash
pdb4amber -i input.pdb -o output.pdb -d -y 
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

使用*ambpdb*生成修改残基名称后的pdb文件，若预测的HIS等的质子化与机理不一致，可以手动在pdb文件中修改，如将HIE-->HIP。
```bash
ambpdb -p 0.15_80_10_pH7.0xxx.top -c 0.15_80_10_pH7.0xxx.crd > protein_H++.pdb
```
到这里，如果蛋白不包含非标准的残基，那其pdb文件基本就处理好了，最后的文件不包括CONNECT等原子间的连接信息，只需要每个原子的三维坐标即可。关于pdb的格式如下图所示，第2列为原子序号，第三列为原子类型，第四列为残基名称，第五列为残基编号，（若蛋白为多链，第五列对应链编号），第6-8列为原子坐标，第9列为occupancy，占有率，一般设置为1，第10列为温度因子，可设置为0，最后一列为元素名称。在导入leap程序中的输入文件，第9，10列可以不需要。

![image8](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/pdb1.png)

## 1.4 非标准残基力场的构建

这里由琮晟写。

## 1.5 构建小分子力场

对于蛋白复合物中的配体和想研究的有机分子，由于他们的结构多样，不像氨基酸的分子构型是确定的，因此需要在模拟前自己构建特定的分子力场。一般在生物体系中对小分子计算其RESP电荷，这是由Kollman等人与1994年发展的方法，非常适用于蛋白，核酸以及有机分子在溶剂相等的模拟，文章链接：1. [A Second Generation Force Field for the Simulation of
Proteins, Nucleic Acids, and Organic Molecules](https://pubs.acs.org/doi/10.1021/ja00124a002) 。但是并不一定使用RESP电荷，一种基于半经验方法的AM1-bcc同样也可以使用，视自己的体系决定，这个在amber官网有详细的教程：2. [计算AM1-bcc电荷](https://ambermd.org/tutorials/basic/tutorial4b/index.php) 。下面介绍一下用gaussian和antechamber来拟合小分子RESP电荷的方法。

&emsp;首先，在计算电荷之前我们也需要知道小分子在`pH=7.0/7.4`的质子化状态，有时候N等原子的质子化对于小分子与蛋白的结合至关重要，这里介绍一下使用*propka3.0*来预测的方法。

* 安装propka
propka需要python 3.6 及以后的版本，可以通过anaconda创建环境然后用pip安装：
```
pip install propka
```
* 用propka预测
用法非常简单，只需要准备小分子的pdb文件。可以用命令行，也可以手动复制粘贴，比如从复合物为6ix5的pdb中取出残基名为BOO的配体：
```
awk '$1=="HETATM"' 6ix5.pdb | awk '$4=="BOO"' > BOO.pdb
```
然后使用propka预测：
```
propka3 BOO.pdb
```
or
```
python -m propka BOO.pdb
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

    antechamber -i BOO.gesp -fi gesp -o BOO.mol2 -fo mol2 -pf y -rn LIG -c resp 

若在高斯优化没有生成gesp文件，可能是高斯版本的问题，请看上面的教程链接。其中，**-pf** 表示删除计算的临时文件，**y** 表示yes， **-rn** 表示将mol2文件中小分子残基名重命名为LIG， **-c** 指定原子电荷为resp。

&emsp;（4）使用*parmchk2*来生成*BOO_resp.frcmod*文件，这是一个参数文件，主要是生成的小分子mol2文件在通用力场**GAFF**中缺失的键长，键角，二面角等参数。
```
parmchk2 -i BOO.mol2 -f mol2 -i BOO_resp.frcmod
```
*BOO_resp.frcmod*将包含所有缺少的参数，或者通过类比类似的参数来填补这些缺失的参数。You should check these parameters carefully before running a simulation. If antechamber can't empirically calculate a value or has no analogy it will either add a default value that it thinks is reasonable or alternatively insert a place holder (with zeros everywhere) and the comment "ATTN: needs revision". In this case you will have to manually parameterise this yourself. 

至此，小分子的力场就构建完成，*BOO.mol2* 和 *BOO_resp.frcmod*包含了小分子的电荷，原子类型，残基名，键长，键角，二面角等信息，在后续的LEaP程序加载复合物pdb时将用到。但应注意的是，用*tleap*加载时，pdb中小分子的原子类型一定要和mol2文件中严格一致。（见后续图）

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

## 2.1 tleap加载蛋白复合物

LEaP程序有GUI界面的xleap也有命令行的tleap，我们这里介绍命令行界面tleap的用法，关于LEaP的介绍可查看[Fundamentals of LEaP](https://ambermd.org/tutorials/pengfei/index.php)。这里以*6ix5_SAM_ambiTS_noH.pdb*为例作为蛋白复合物，其中包含了*SAM*辅因子和*BOO*小分子配体，用`tleap -i tleap.in`载入下述tleap.in输入文件：
```
source leaprc.ff14SB
source leaprc.water.tip3p
source leaprc.phosaa10
loadamberparams frcmod.ions1lm_126_tip3p    
source leaprc.gaff
loadamberparams TS-1_resp.frcmod 
loadamberparams SAM_resp.frcmod 
SAM = loadmol2 SAM_resp.mol2
BOO = loadmol2 BOO_resp.mol2
mol = loadpdb 6ix5_SAM_ambiTS_noH.pdb
solvateBox mol TIP3PBOX 10.0
addions mol Na+ 0
addions mol Na+ 70
addions mol Cl- 70
savepdb mol 6ix5_complex_solv.pdb  
saveamberparm mol min.prmtop min.inpcrd
```
为了运行分子动力学模拟, 我们需要加载力场来描述复合物的势能. 对蛋白质一般使用AMBER的*FF14SB*力场, *FF14SB*基于*FF12SB*, *FF12SB*是*FF99SB*的更新版本, 而*FF99SB*力场又是基于原始的Amber的Cornell等人(1995)的*ff94*力场。*FF14SB*力场最显著的变化包括更新了蛋白质*Phi-Psi*的扭转项, 并重新拟合了侧链的扭转项. 这些变化一起改进了对这些分子中α螺旋的估计。`source`命令用于加载力场，*leaprc.water.tip3p*为*TIP3P*水盒子模型的力场，*phosaa10*表示磷酸化修饰氨基酸的力场，*ions1lm_126_tip3p*表示tip3p水中+1，-1离子的参数，`solvatebox`命令对系统进行溶剂化，`addions mol Na+ 0`命令使用counter ions 对体系电荷进行平衡，`addions mol Na+/Cl- 70`添加盐离子至0.15 mM，`saveamberparm`保存溶剂化之后体系的拓扑文件（prmtop）和坐标文件（inpcrd）。小分子和辅因子的mol2文件和frcmod见文件夹[/parm](https://github.com/YugroupSUStech/MDtutorial/tree/main/parm)，这里需要注意复合物pdb中配体的原子顺序与mol2文件的可以不一致，但原子类型要和mol2文件中要严格一致！！！

退出tleap请用`quit`。如果在载入蛋白时报错，一定先查看`tleap.log`文件，看看是哪一步出错，一般在载入小分子时出错很多，如果出现以下错误，很有可能是pdb文件中小分子的原子类型错误，与构建的mol2等力场文件不一致，或者残基名与mol2文件不一致，请仔细检查。其他错误可以将报错信息用google搜索。（不建议百度）
```
FATAL: Atom XXX does not have a type
```



