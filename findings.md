# Findings：VR 剑仙小镇 Godot Demo

## 已确认需求

- Demo 采用 Godot，而不是 Unity/Unreal。
- PCVR / SteamVR 优先，后续可评估 Meta Quest 独立版。
- 视觉风格为国风写实低多边形 / Stylized Realistic。
- 主流程采用“找回飞剑 + 小妖试炼 + 御剑返镇”。
- 场景需要大尺度小镇和山川，但核心可玩区保持可控。
- 交互以站立施法小法术为主，不做复杂近战。
- 移动提供舒适/沉浸双模式，默认舒适模式。

## Godot XR 研究结论

- 推荐 Godot 4.6+、OpenXR、Godot XR Tools。
- PCVR 通过当前系统 active OpenXR runtime，通常为 SteamVR。
- VR 中应避免重度后处理、大量动态灯和高面数角色堆叠。
- Quest 后续应作为独立性能档处理，材质、灯光、粒子和场景密度需要可降级。

## 计划拆解原则

- 先建立可运行项目和自动测试，再逐步加系统。
- 每个任务必须有可验证输出。
- 场景采用灰盒和程序化低模资产起步，后续替换美术不影响逻辑。
