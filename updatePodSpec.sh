#!/bin/bash
#使用方法：将此脚本放置在和podspec文件同级目录 然后chmod +x ./updatePodSpec.sh 
#         根据下面几个配置参数的描述进行配置
#         执行脚本


#可以手动设定POD_NAME用于一个目录有多个podspec文件的时候 如果目录下只有一个podspec文件则设置成空字符串即可
POD_NAME=""
#是否需要pod lib lint 校验spec文件
NEED_CHECK=0
#是否上传json的spec文件
USE_JSON=1
#私有specs的git仓库路径如果不设置 则选择和当前工程目录同级别
SPECS_REPO_PATH=""
#私有仓库的spec仓库URL
PRIVATE_SPECS_REPO_URL=""



specFileExtention="podspec"
basepath=$(cd `dirname $0`; pwd)

function logError() {
	echo -e "\033[0;31m$*\033[0m"
}
function logMsg() {
	echo -e "\033[0;32m$*\033[0m"
}
function rmJsonIfNeeds() {
	if [[ USE_JSON -eq 1 ]]; then
		#statements
		rm -rf "${basepath}/${POD_NAME}.${specFileExtention}.json"
		logMsg '删除json文件!'
	fi
}
if [[ "$PRIVATE_SPECS_REPO_URL" -eq "" ]]; then
	#statements
	logError "必须手动设置PRIVATE_SPECS_REPO_URL，否则无法更新仓库！ 脚本结束！"
	exit 1
fi
if [[ $SPECS_REPO_PATH == */ ]]; then
	#statements
	# logMsg SPECS_REPO_PATH "末尾有/ 去掉"
	SPECS_REPO_PATH=${SPECS_REPO_PATH%/*}
	# logMsg $SPECS_REPO_PATH
fi

#如果POD_NAME设置成空字符串 则自动在当前路径寻找.podspec后缀的文件
if [[ "$POD_NAME" -eq "" ]]; then
	logMsg "没有手动设置POD_NAME 自动查找spec文件"
	#statements
	for file in ./*; do
    if [[ "$file" =~ ".$specFileExtention" ]]; then
    	#statements
    	POD_NAME=${file%.*}
    	POD_NAME=${POD_NAME#*/}
    	logMsg $POD_NAME
    	break
    fi
	done
fi
#获取当前路径
if [[ "$SPECS_REPO_PATH" -eq "" ]]; then
	#statements
	logMsg "未设置SPECS_REPO_PATH，自动生成..."
	SPECS_REPO_PATH=${basepath%/*}
	repoExtention=${PRIVATE_SPECS_REPO_URL##*/}
	repoExtention=${repoExtention%.*}
	SPECS_REPO_PATH="$SPECS_REPO_PATH/$repoExtention"
	logMsg "SPECS_REPO_PATH："$SPECS_REPO_PATH
fi

event="Update"
filename="${basepath}/${POD_NAME}.$specFileExtention"

logMsg "当前的podspec：${filename}"
version=""
#获取version
logMsg "获取version"
var=0
for  line  in  `cat ${filename}`
do
	if [[ $var -eq 2 ]]; then
		#statements
		version=${line#*\'}
		version=${version%\'*}
		logMsg "version:"$version
		# logMsg "获取version完成！"
		break
	fi
	if [[ $var -eq 1 && "$line" =~ "=" ]]; then
		var=2
	fi
	if [[ "$line" =~ ".version" ]]; then
		var=1
	fi
	# logMsg $line
done
if [[ "$?" -ne "0" ]]; then
	#statements
	logError '读取文件失败！'
	exit 1
fi
# 如果version长度为0则说明获取version异常
if [[ ${#version} -eq 0 ]]; then
	#statements
	logError '获取version失败！'
	exit 1
fi
version=${version#'"'}
version=${version%'"'}
cmpFile=$filename
if [[ USE_JSON -eq 1 ]]; then
	#statements
	logMsg '使用json文件，开始生成...'
	cmpFile="${filename}.json"
	if [[ ! -d "${cmpFile}" ]]; then
		#statements
		rm -rf $cmpFile
	fi
	pod ipc spec $filename >> $cmpFile
	if [[ "$?" -ne "0" ]]; then
		#statements
		logError '生成spec.json文件失败！'
		exit 1
	fi
	logMsg '生成json文件成功!'
fi
# logMsg $version
#退出一级目录并查找components

path=$SPECS_REPO_PATH
if [[ ! -d "${path}" ]]; then
	logMsg "路径不存在 clone ..."
	path=${path%/*}
	cd $path
	git clone -b master $PRIVATE_SPECS_REPO_URL
	if [[ "$?" -ne "0" ]]; then
		#statements
		logError 'git clone 失败 请重试！'
		rmJsonIfNeeds
		exit 1
	fi
else
	logMsg "路径存在 pull ..."
	cd $path
	git pull
	if [[ "$?" -ne "0"  ]]; then
		#statements
		logError 'git pull 失败 请手动处理仓库！'
		rmJsonIfNeeds
		exit 1
	fi
fi
path="${SPECS_REPO_PATH}/${POD_NAME}"
if [[ ! -d "${path}" ]]; then
	#statements
	event="Add"
	logMsg $path "路径不存在 创建..."
	mkdir -p "${path}"
fi
path="${path}/${version}"
if [[ ! -d "${path}" ]]; then
	#如果路径不存在，创建
	#statements
	event="Add"
	logMsg $path "路径不存在 创建..."
	mkdir -p "${path}"
else
	#如果路径存在，比较文件差异
	logMsg $path "路径存在 比较spec文件 ..."
	fileExtention=$specFileExtention
	if [[ USE_JSON -eq 1 ]]; then
		#statements
		fileExtention="${specFileExtention}.json"
	fi
	diff "${path}/${POD_NAME}.$fileExtention" $cmpFile
	if [ "$?" -eq "0" ]; then
	    logMsg "spec文件没有更新！脚本结束！"
	    rmJsonIfNeeds
	    exit 0
	else

	    logMsg "spec文件有更新！"
	    event="Update"
	fi

fi
if [[ $NEED_CHECK -eq 1 ]]; then
	#statements
	logMsg "设置需要校验 开始校验spec文件..."
	cd $basepath
	pod lib lint --sources='$PRIVATE_SPECS_REPO_URL,https://github.com/CocoaPods/Specs.git,https://github.com/cocoapods/specs.git'
	if [[ "$?" -ne "0" ]]; then
		#statements
		logError "spec 文件校验未通过！"
		rmJsonIfNeeds
		exit 1
	fi
fi
logMsg "拷贝spec文件 ..."
cp "${basepath}/${POD_NAME}.$fileExtention" "${path}/${POD_NAME}.$fileExtention"
if [[ "$?" -ne "0"  ]]; then
		#statements
		logError '拷贝文件时发生错误！请查看日志！'
		rmJsonIfNeeds
		exit 1
fi
cd $SPECS_REPO_PATH
logMsg "提交更改代码 ..."
git add ./
git commit -m "[${event}] ${POD_NAME} (${version})"
if [[ "$?" -ne "0"  ]]; then
	#statements
	logError 'git commit 失败 请手动处理仓库！'
	rmJsonIfNeeds
	exit 1
fi
git push
if [[ "$?" -ne "0"  ]]; then
		#statements
		logError 'git push 失败 请手动处理仓库！'
		rmJsonIfNeeds
		exit 1
fi
rmJsonIfNeeds
logMsg "上传成功！ spec文件更新完成！ 脚本结束！"
