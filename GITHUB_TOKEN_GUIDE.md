# 生成 GitHub Personal Access Token 步骤

## 1. 访问 GitHub Token 设置页面

在浏览器中打开：
https://github.com/settings/tokens

## 2. 生成新的 Token

1. 点击 **"Generate new token"** (或 "Generate new token (classic)")
2. 设置 Token 名称（备注），例如：`moodiary-push`
3. 设置过期时间（建议选择：No expiration 或 90 days）
4. 勾选权限（Scopes）：
   - ✅ **repo** (Full control of private repositories)
     - repo:status
     - repo_deployment
     - repo_public_repo
     - repo:invite
     - repo:security_events
     - repo:actions
   - ✅ **workflow** (如果需要 GitHub Actions)

5. 点击 **"Generate token"**

## 3. 复制 Token

⚠️ **重要**：生成后立即复制 token，因为它只显示一次！

## 4. 在 WSL 终端中使用 Token 推送

返回 WSL 终端，运行：
```bash
cd ~/projects/moodiary
git push
```

当提示时输入：
- **Username**: 你的 GitHub 用户名（例如：northeast18）
- **Password**: 粘贴刚才生成的 Token（不是你的 GitHub 密码！）

Token 格式类似：`ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

## 5. 完成

推送成功后，你就可以在 GitHub 上创建 Release 了！
