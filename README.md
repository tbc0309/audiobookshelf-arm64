# Audiobookshelf ARMv8 / ARM64 自动构建

[![编译并发布 Audiobookshelf ARM64](https://github.com/tbc0309/audiobookshelf-arm64/actions/workflows/build-armv8.yml/badge.svg)](https://github.com/tbc0309/audiobookshelf-arm64/actions/workflows/build-armv8.yml)

在 GitHub Actions 的 x86_64 Runner 上，通过 QEMU 运行完整 ARM64 Node.js 环境，自动生成：

- `audiobookshelf-<版本>-linux-arm64`：ARMv8/ARM64 独立二进制文件
- `audiobookshelf_<版本>_arm64.deb`：Debian/Ubuntu ARM64 安装包
- `.tar.gz` 压缩包和 `SHA256SUMS`

> 非 Audiobookshelf 官方项目。源码来自 `advplyr/audiobookshelf`，请遵守其 GPL-3.0 许可证。

## 自动构建

工作流每天检查一次上游最新正式 Release。发现尚未发布的新版本时，会自动编译并创建本仓库 Release；相同版本已有 `abs-v<版本>-arm64` Release 时不会重复构建。

也可打开 **Actions → 编译并发布 Audiobookshelf ARM64 → Run workflow**，将 `version` 设为 `latest` 或明确版本号，并选择是否发布 Release。

## DEB 安装

```bash
sudo apt install ./audiobookshelf_<版本>_arm64.deb
sudo systemctl status audiobookshelf
```

默认配置：

- 端口：`13378`
- 配置目录：`/var/lib/audiobookshelf/config`
- 元数据目录：`/var/lib/audiobookshelf/metadata`
- systemd 用户：`audiobookshelf`

修改参数：

```bash
sudo systemctl edit audiobookshelf
```

写入：

```ini
[Service]
Environment=ABS_PORT=13378
Environment=ABS_CONFIG_PATH=/你的/config目录
Environment=ABS_METADATA_PATH=/你的/metadata目录
```

随后执行：

```bash
sudo systemctl daemon-reload
sudo systemctl restart audiobookshelf
```

## 群晖说明

`.deb` 主要面向 Debian/Ubuntu ARM64。群晖 DSM 通常不使用 Debian 包管理体系，可直接提取或下载独立二进制：

```bash
chmod +x audiobookshelf-<版本>-linux-arm64
ABS_PORT=13378 \
ABS_CONFIG_PATH=/volume1/@appdata/audiobookshelf/config \
ABS_METADATA_PATH=/volume1/@appdata/audiobookshelf/metadata \
./audiobookshelf-<版本>-linux-arm64
```

目标机器执行 `uname -m` 应显示 `aarch64`。若出现 `GLIBC_x.xx not found`，说明 `pkg` 使用的 Node ARM64 runtime 与目标 DSM 的 glibc 不兼容，而不是文件架构错误。

## 本地 x86_64 构建

要求 Docker、Buildx、QEMU/binfmt、Git、dpkg-deb：

```bash
sudo docker run --privileged --rm tonistiigi/binfmt --install arm64
./scripts/build-arm64.sh 2.36.0
./scripts/build-deb.sh 2.36.0
./scripts/package-release.sh 2.36.0
```

输出位于 `dist/`。

## 构建原理

Audiobookshelf 的打包配置包含 `sqlite3` 原生 `.node` binding。因此不能只在 x86_64 主机执行交叉目标打包；`npm ci` 也必须在 ARM64 用户态完成。本项目通过 QEMU 启动 `linux/arm64` 容器，使前端构建、服务端依赖安装和 `pkg` 打包全部发生在 ARM64 环境中。

## 许可证

本仓库的构建脚本采用 [MIT License](LICENSE) 发布。生成物包含的 Audiobookshelf 程序仍遵循上游的 [GPL-3.0 License](https://github.com/advplyr/audiobookshelf/blob/master/LICENSE)，其他依赖保留各自许可证。本项目与 Audiobookshelf 官方无隶属关系。
