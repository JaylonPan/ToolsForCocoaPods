# ToolsForCocoaPods
Tools for CocoaPods

## updatePodSpec.sh
这个脚本用于自动提交自己工程目录下的spec文件到对应的repo去，避免我们维护两份spec文件，并且同步不及时的问题，您也可以将此脚本设置在本地的push hooks里面来执行。
#### 将脚本拷贝到和你的仓库中spec文件同级目录下。
#### 然后
`
cd yourProjectPath
`
#### 然后
`
chmod +x ./updatePodSpec.sh 
`
#### 然后通过文本编辑器打开脚本
#### 配置如下选项
#### 可以手动设定POD_NAME用于一个目录有多个podspec文件的时候 如果目录下只有一个podspec文件则设置成空字符串即可
`
POD_NAME=""
`
#### 是否需要`pod lib lint `校验spec文件
`
NEED_CHECK=0

#### 是否上传json文件默认是1，直接上传podspec文件设成0

USE_JSON=1
`
#### 私有specs的git仓库路径如果不设置 则选择和当前工程目录同级别
`
SPECS_REPO_PATH=""
`
#### 私有仓库的spec仓库URL
`
PRIVATE_SPECS_REPO_URL=""
`

#### 其中PRIVATE_SPECS_REPO_URL必须配置，不然无法找到对应的spec仓库去提交spec文件的更新

#### 最后执行脚本
`
  ./updatePodSpec.sh
`
