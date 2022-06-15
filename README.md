# MDtutorial
This tutorial is available for Yu group new members
# MD模拟前的准备工作
## 构建模型
这里有一张图是关于Amber的整个流程，可以了解一下：

![image](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/amberflow.png)

首先从蛋白质数据库中下载需要的PDB文件，(https://www.rcsb.org/) 网站中可以看到蛋白的一些信息，例如是否含有突变位点等。下载后的PDB文件需要检查其序列的完整性，这是因为在MD中的输入文件默认不同链间用*TER*分隔开，没有*TER*则认为相邻原子连接在一起。若有缺失序列需要首先进行同源模建：

&emsp;关于同源模建的方法有很多，主要基于MSA（多序列比对），也可使用蛋白质预测在线服务器如trRosetta2.0, (https://yanglab.nankai.edu.cn/trRosetta/) ，在指定位置输入蛋白的序列，序列可以从pdb库中获得，如下图所示：

![image2](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/trrosetta.png)

等待几小时后可以得到预测的结构，一般的*TM-score*>0.5，结果可靠，分数最高的**model1**可以作为最后结果。

![image3](https://github.com/YugroupSUStech/MDtutorial/blob/main/IMG/trrosetta2.png)

