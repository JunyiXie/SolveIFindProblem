# 模块间耦合

[![CI Status](https://img.shields.io/travis/junyixie/OpenAPM.svg?style=flat)](https://travis-ci.org/junyixie/OpenAPM)
[![Version](https://img.shields.io/cocoapods/v/OpenAPM.svg?style=flat)](https://cocoapods.org/pods/OpenAPM)
[![License](https://img.shields.io/cocoapods/l/OpenAPM.svg?style=flat)](https://cocoapods.org/pods/OpenAPM)
[![Platform](https://img.shields.io/cocoapods/p/OpenAPM.svg?style=flat)](https://cocoapods.org/pods/OpenAPM)

## **写着玩的 练练解耦合**

## 结构
- Coordinator 协调器，协调模块调用，配置，初始化，事件。
    - Config 配置模块
    - DefineProcotol 定义的协议，组件依赖协议进行解耦
    - EventTriger 事件触发，事件代理
    - Mananger 管理module,service,event
- Monitor 监控模块

## Author

junyixie, xiejunyi19970518@outlook.com

## License

OpenAPM is available under the MIT license. See the LICENSE file for more info.
