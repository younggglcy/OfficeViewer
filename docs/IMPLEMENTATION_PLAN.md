# OfficeViewer 签名和更新机制改进计划

## 确认的方案

| 项目 | 决定 |
|------|------|
| 代码签名 | Ad-hoc 签名（确保 Apple Silicon 兼容） |
| 分发渠道 | GitHub Releases + Homebrew Tap |
| 更新机制 | Sparkle：启动时检查 + 菜单栏手动检查 |

---

## 实施步骤

### Phase 1: 集成 Sparkle 自动更新框架

#### 1.1 添加 Sparkle 依赖
- 在 Xcode 中通过 Swift Package Manager 添加 `https://github.com/sparkle-project/Sparkle`
- 修改 `project.pbxproj` 添加框架引用

#### 1.2 生成 EdDSA 密钥对
```bash
# 下载 Sparkle 后运行
./bin/generate_keys
```
- 私钥：保存到 GitHub Secrets `SPARKLE_PRIVATE_KEY`
- 公钥：添加到 Info.plist

#### 1.3 修改 Info.plist
添加以下键值：
```xml
<key>SUFeedURL</key>
<string>https://raw.githubusercontent.com/younggglcy/OfficeViewer/main/appcast.xml</string>
<key>SUPublicEDKey</key>
<string>YOUR_EDDSA_PUBLIC_KEY</string>
<key>SUEnableAutomaticChecks</key>
<true/>
```

#### 1.4 修改 OfficeViewerApp.swift
- 导入 Sparkle 框架
- 创建 `SPUStandardUpdaterController` 实例
- 在菜单栏添加"检查更新..."选项
- 启动时自动检查更新

### Phase 2: 更新构建流程

#### 2.1 修改 `.github/workflows/release.yml`
添加以下步骤：

1. **Ad-hoc 代码签名**
```bash
codesign --force --deep --sign "-" OfficeViewer.app
```

2. **生成 Sparkle 签名**
```bash
./bin/sign_update OfficeViewer-${VERSION}.dmg
```

3. **更新 appcast.xml**
- 自动生成/更新 appcast.xml
- 包含版本号、下载链接、EdDSA 签名

#### 2.2 创建 appcast.xml 模板
```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>OfficeViewer Updates</title>
    <item>
      <title>Version X.Y.Z</title>
      <sparkle:version>X.Y.Z</sparkle:version>
      <sparkle:shortVersionString>X.Y.Z</sparkle:shortVersionString>
      <pubDate>DATE</pubDate>
      <enclosure url="https://github.com/younggglcy/OfficeViewer/releases/download/vX.Y.Z/OfficeViewer-X.Y.Z.dmg"
                 sparkle:edSignature="SIGNATURE"
                 length="SIZE"
                 type="application/octet-stream"/>
    </item>
  </channel>
</rss>
```

### Phase 3: 创建 Homebrew Tap

#### 3.1 创建仓库 `younggglcy/homebrew-tap`

#### 3.2 创建 Cask formula
文件：`Casks/officeviewer.rb`
```ruby
cask "officeviewer" do
  version "0.1.1"
  sha256 "HASH"

  url "https://github.com/younggglcy/OfficeViewer/releases/download/v#{version}/OfficeViewer-#{version}.dmg"
  name "OfficeViewer"
  desc "Open Office files and view their XML structure"
  homepage "https://github.com/younggglcy/OfficeViewer"

  app "OfficeViewer.app"

  zap trash: [
    "~/Library/Caches/OfficeViewer",
    "~/Library/Preferences/name.younggglcy.OfficeViewer.plist",
  ]
end
```

#### 3.3 更新发布工作流
- 自动计算 DMG 的 SHA256
- 自动更新 Homebrew formula（通过 GitHub Action）

### Phase 4: 文档更新

#### 4.1 更新 README.md
- 添加 Homebrew 安装方式
- 更新 Gatekeeper 绕过说明（针对 macOS Sequoia）

---

## 关键文件变更清单

| 文件 | 操作 | 内容 |
|------|------|------|
| `OfficeViewer.xcodeproj/project.pbxproj` | 修改 | 添加 Sparkle SPM 依赖 |
| `OfficeViewer/info.plist` | 修改 | 添加 SUFeedURL、SUPublicEDKey、SUEnableAutomaticChecks |
| `OfficeViewer/OfficeViewerApp.swift` | 修改 | 集成 Sparkle 更新控制器，添加菜单项 |
| `.github/workflows/release.yml` | 修改 | Ad-hoc 签名、Sparkle 签名、更新 appcast |
| `appcast.xml` | 新建 | Sparkle 更新源 |
| `README.md` | 修改 | 添加 Homebrew 安装说明 |

**外部仓库**:
| 仓库 | 操作 |
|------|------|
| `younggglcy/homebrew-tap` | 新建 |
| `homebrew-tap/Casks/officeviewer.rb` | 新建 |

---

## 验证方式

### 1. Ad-hoc 签名验证
```bash
codesign -dv --verbose=4 /Applications/OfficeViewer.app
# 应该显示签名信息，Signature 为 "adhoc"
```

### 2. Sparkle 更新测试
1. 安装当前版本（如 0.1.1）
2. 发布新版本（如 0.2.0）
3. 启动应用，检查是否弹出更新提示
4. 或点击菜单栏"检查更新..."

### 3. Homebrew 安装测试
```bash
brew tap younggglcy/tap
brew install --cask officeviewer
# 验证应用正常启动
```

---

## 依赖项

- [Sparkle 2.x](https://github.com/sparkle-project/Sparkle) - MIT License
- GitHub Actions runner: `macos-latest`

## 参考资源

- [Sparkle 官方文档](https://sparkle-project.org/documentation/)
- [Publishing an update](https://sparkle-project.org/documentation/publishing/)
- [Homebrew Cask 维护指南](https://docs.brew.sh/Cask-Cookbook)
