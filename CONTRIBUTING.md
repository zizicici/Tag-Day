# Contributing to Tag Day

感谢你愿意为 Tag Day 贡献代码。

## 贡献方式

- 提交 Bug：使用 Issue，提供可复现步骤、设备型号、iOS 版本、预期行为与实际行为
- 提交功能建议：说明使用场景、收益和可能的交互方式
- 提交代码：通过 Pull Request（PR）

## 开发前准备

1. 安装 Xcode 16+
2. 克隆仓库并打开 `Tag Day.xcodeproj`
3. 确认可编译运行 `Tag Day` 与 `Tag Widget`
4. 如果改动涉及 Widget/备份/通知，请配置相应 Capabilities（App Group、iCloud、Notification）

## 分支与提交建议

- 分支命名建议：`feature/<name>`、`fix/<name>`、`refactor/<name>`
- 提交信息建议使用简洁前缀：
  - `feat:` 新功能
  - `fix:` 修复问题
  - `refactor:` 重构
  - `docs:` 文档
  - `chore:` 工程维护

示例：

```text
feat: add record filtering in overview
fix: correct tag reorder persistence
docs: improve setup section in README
```

## PR Checklist

提交 PR 前请自查：

- [ ] 代码可以在本地构建通过（至少主 App）
- [ ] 变更点有对应说明（为什么改、改了什么）
- [ ] 不包含无关格式化或大范围噪声改动
- [ ] 涉及 UI 的改动，提供截图或录屏
- [ ] 涉及数据逻辑改动，说明兼容性与风险
- [ ] 更新相关文档（如 README）

## 代码风格

- 遵循现有代码风格，优先保持一致性
- 命名清晰，避免缩写歧义
- 在复杂逻辑处添加必要注释
- 避免引入未使用依赖

## 测试建议

当前项目尚未建立完整自动化测试体系。请至少进行手工验证：

- 日历新增/编辑/删除记录
- 标签与记录本增删改查
- Widget 展示与交互
- App Intents 调用
- 备份导入导出流程

## 行为准则

请保持专业、尊重、可协作的沟通方式。  
讨论聚焦在问题本身，避免人身化表达。
