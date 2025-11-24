# libmpv-apple-build
- 由 libmpv-linux-build 复制修改而来

## 编译
- docker 拉取镜像 `ubuntu:20.04`，创建容器，进入容器
- cd ${项目根目录}/buildscripts/
- 执行编译 ./bundle_default.sh
- 编译结果在 ${项目根目录}/output/x86_64

## 依赖库预装
- 部分库由系统库提供，编译时报错缺少的库直接 apt 安装即可