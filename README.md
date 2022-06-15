# MDtutorial
This tutorial is available for Yu group new members
# MD模拟前的准备工作
## 构建模型
这里有一张图是关于Amber的整个流程，可以了解一下：

![image](https://github.com/YugroupSUStech/MDtutorial/edit/main/IMG/amberflow.png)

首先从蛋白质数据库中下载需要的PDB文件，(https://www.rcsb.org/)网站中可以看到蛋白的一些信息，例如是否含有突变位点等。下载后的PDB文件需要检查其序列的完整性，这是因为在MD中的输入文件默认不同链间用“TER”分隔开，没有“TER”则认为相邻原子连接在一起。若有缺失序列需要首先进行同源模建：
