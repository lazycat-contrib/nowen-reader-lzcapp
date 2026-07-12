# NowenReader - 懒猫应用

每天定时检查 NowenReader 稳定版本，并支持 `v*` tag 和手动触发懒猫官方商店与喵喵私有商店发布。

轻量开源、本地化优先的漫画/同人志管理与阅读一体化工具。

## 📖 应用简介

NowenReader 是一款对标 LANraragi 核心体验的漫画管理工具，聚焦本地漫画资源的归档整理、元数据智能管理与沉浸式阅读，为漫画爱好者打造私域、可控、高效的个人漫画图书馆。

**主要功能：**
- 📚 漫画归档整理
- 🔍 元数据智能管理
- 📱 沉浸式阅读体验
- 🏠 本地化优先，私域可控

## 🚀 快速开始

### 安装

1. 确保已安装 `lzc-cli` 工具
2. 准备应用图标 `icon.png` (512x512 PNG 格式)
3. 运行构建脚本

```bash
# 赋予执行权限
chmod +x build.sh

# 方式一：交互式菜单
./build.sh

# 方式二：直接命令
./build.sh build    # 构建
./build.sh copy     # 复制镜像
./build.sh publish  # 发布
./build.sh one-click # 一键完成全部流程
```

### 本地安装测试

```bash
# 构建完成后
lzc-cli app install NowenReader-1.0.0.lpk
```

## 📁 目录结构

```
nowen-reader-lzcapp/
├── package.yml        # LPK v2 应用元数据
├── lzc-manifest.yml   # 应用运行清单
├── lzc-build.yml      # 构建配置
├── build.sh           # 自动化脚本
├── icon.png           # 应用图标 (需准备)
└── README.md          # 本文档
```

## 📂 存储路径

应用使用以下存储路径：

| 路径 | 用途 | 说明 |
|------|------|------|
| `/lzcapp/var/data` | 数据库 | 存储应用数据库文件 |
| `/lzcapp/cache/app` | 缓存 | 存储临时缓存数据 |
| `/lzcapp/var/comics` | 漫画 | 存储漫画文件 |

## 📚 漫画目录配置

### 方式一：使用懒猫存储路径（推荐）

安装后，漫画文件存放在 `/lzcapp/var/comics` 目录。

### 方式二：挂载现有 NAS 目录

如果您有 NAS 上的现有漫画库，可以使用以下方法：

1. **软链接方式**（推荐）
   ```bash
   # 在懒猫主机上创建软链接
   ln -s /vol1/1000/漫画 /lzcapp/var/comics
   ```

2. **修改安装包**（高级）
   - 修改 `lzc-manifest.yml` 中的 `binds` 配置
   - 将 `/lzcapp/var/comics:/app/comics` 改为您的 NAS 路径
   - 重新构建应用

### 方式三：导入现有漫画

```bash
# 将 NAS 漫画复制到懒猫存储
cp -r /vol1/1000/漫画/* /lzcapp/var/comics/
```

## ⚙️ 环境变量

应用默认使用以下环境变量：

| 变量 | 值 | 说明 |
|------|-----|------|
| `GIN_MODE` | release | 运行模式 |
| `DATABASE_URL` | /data/nowen-reader.db | 数据库路径 |
| `COMICS_DIR` | /app/comics | 漫画目录 |
| `DATA_DIR` | /app/.cache | 缓存目录 |
| `PORT` | 3000 | 服务端口 |
| `TZ` | Asia/Shanghai | 时区 |

## 🔧 开发说明

### 首次发布流程

```bash
# 1. 登录懒猫应用商店
lzc-cli appstore login

# 2. 一键发布
./build.sh one-click
```

### 更新发布流程

```bash
# 1. 更新版本号
# 编辑 package.yml 中的 version 字段

# 2. 重新发布
./build.sh one-click
```

## 📝 注意事项

1. **图标准备**：发布前需要准备 512x512 的 PNG 格式图标
2. **漫画目录**：默认路径 `/lzcapp/var/comics`，可根据需要调整
3. **内存配置**：默认限制 512M，可根据漫画库大小调整
4. **审核周期**：应用商店审核通常需要 1-3 天

## 🔗 相关链接

- **项目主页**: https://github.com/cropflre/nowen-reader
- **懒猫开发文档**: https://developer.lazycat.cloud

## 📜 许可证

MIT License
