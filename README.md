# MDtutorial
This tutorial is available for Yu group new members
# MD模拟前的准备工作
## 1. 构建模型
这里有一张图是关于Amber的整个流程，可以了解一下：

![image](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/amberflow.png)

首先从蛋白质数据库中下载需要的PDB文件，(https://www.rcsb.org/) 网站中可以看到蛋白的一些信息，例如是否含有突变位点等。下载后的PDB文件需要检查其序列的完整性，这是因为在MD中的输入文件默认不同链间用*TER*分隔开，没有*TER*则认为相邻原子连接在一起。若有缺失序列需要首先进行同源模建：

### 同源模建
&emsp;关于同源模建的方法有很多，主要基于MSA（多序列比对），也可使用蛋白质预测在线服务器如trRosetta2.0, (https://yanglab.nankai.edu.cn/trRosetta/) ，在指定位置输入蛋白的序列，序列可以从pdb库中获得，如下图所示：

![image2](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/trrosetta.png)

等待几小时后可以得到预测的结构，一般的*TM-score*>0.5，结果可靠，分数最高的**model1**可以作为最后结果。

![image3](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/trrosetta2.png)

&emsp;另外也可以使**Swiss-model**进行建模，也非常简便，步骤与上述类似，详细网址：(https://swissmodel.expasy.org/) **Swiss-model**建模简单方便，可靠性高，但是它不能进行多模板建模。

## 2. 处理pdb文件
这就要用到上面介绍的*pdb4amber*命令，在使用前可以用
```bash
pdb4amber -h
```
来查看此命令的用法， 下载的pdb文件可能包含一些非标准残基和配体或者辅因子，为方便后面预测残基的质子化状态我们可以先用*pdb4amber*去除这些残基，
```bash
pdb4amber -i input.pdb -o output.pdb -d -y 
```
其中，**-d** 表示 删掉所有水分子， **-y** 表示删掉所有氢原子，此命令除了输出**output.pdb** 还会将非标准残基输出到**xxx_nonstand.pdb**中。另外也会对所有的残基重新从1开始编号，使文件格式更标准。

## 3. 预测质子化状态
用X-ray方法解析的蛋白质不含氢，因为该无法解析它们。 LEaP程序会依据标准质子化状态，根据最佳氢键向这些残基自动添加氢原子。因此，如果不对重要的残基重命名，具有非标准质子化状态的氨基酸将被错误地质子化。例如，在 Asp 蛋白酶中，ASP并不一定是非质子化的（带负电），为了防止这种情况，必须将非标准ASP重命名为ASH（质子化的Asp，不带电）。使用正确的残基名，LEaP 将正确地为残基添加氢，下表显示了一些常见质子化状态的重命名。

![image4](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/proton.png)

下面介绍用**H++ server**来预测质子化状态：












