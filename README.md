# CPU_WRAPPER Spec

## slv接口

验证环境需要接对应的mst

+ CPU AXI
  + cpu的对外接口，可以访问所有slv ， 直接接到axi node上
+ mem 
  + 用于访问sram和rom， 直接接到axi node上，经过内置axi2ram，axi2rom转换后送到对外访问ram rom接口
+ rbc
  + 用于访问寄存器如 public reg ， private reg， 还有路由到系统rbc mst总线，访问其他地址寄存器，不经过axi node，直接访问寄存器

## mst接口

验证环境中需要接对应的slv

+ axi hub
  + 用于访问hbm等，需要外接hub然后送到系统fabric， 由axi node而来
+ ram
  + 访问系统ram，由axi2ram而来

+ rom
  + 访问系统rom，由axi2ram而来
+ public reg
  + 寄存器mst接口，可能来自rbc和cpu经过axi node，再经过axi2reg而来
+ private reg
  + 寄存器mst接口，可能来自rbc和cpu经过axi node，再经过axi2reg而来
+ rbc 
  + 访问其他系统寄存器，可能来自rbc和cpu经过axi node，再经过axi2reg而来

## 内部axi node

内部fabric是128bit axi的总线，所以内置协议转换模块



现有svt axi vip， rbc agent(mst, slv), reg vip, mem vip。 
