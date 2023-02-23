# Dnspod-DDNS-with-BashShell
利用Dnspod的API和shell脚本搭建自己的动态域名服务。如果你使用这个脚本，建议点watch以获取更新通知。  
本脚本测试适用于大部分sh和bash环境，仅依赖curl命令，对大多数系统来说都是开箱即用。如有兼容性问题欢迎提出issue。  

## 使用方法
本脚本分为两个版本，一个是获取自己外网ip的版本dnspod_ddns.sh，一个是直接获取自己网卡设备上的ip的版本dnspod_ddns_line.sh（对于多拨或者路由器网关用户适用）。
### 获取API的ID和Token
API的ID和Token可以在后台获取：  
请参见官方文档：https://docs.dnspod.cn/account/dnspod-token/  

### **dnspod_ddns.sh**
#### 参数说明  
>在脚本开头#CONF START到#CONF END之间为用户所需填写的参数:  

参数|填写说明
:-:|:-
|API_ID | 在个人中心后台的安全设置里面获取ID|
API_Token|在个人中心后台的安全设置里面获取Token
domain| 你所注册的主域名，例如```baidu.com```，```qq.com```，```china.edu.cn```，```example.com```
sub_domain|主机记录名，例如```www.baidu.com```的主机记录名是```www```，```image.www.weibo.com```的主机记录是```image.www```，```myhome.example.com```的主机记录名是```myhome```
CHECKURL|用于检查自己的外网IP是什么的网址，注释掉该参数会跳过本地DNS检查比对，直接执行（验证域名记录是否存在以及记录是否重复后）更新；建议的备选CHECKURL：```http://ipsu.03k.org``` ```https://www.cloudflare.com/cdn-cgi/trace```
OUT|指定使用某个网卡设备进行联网通信（默认被注释掉）。注意，一些系统的负载均衡功能可能会导致该参数无效。推荐使用```ip a```命令或者```ifconfig```命令查看网卡设备名称。
#### **推荐的部署方法**
把如上所述的参数填好即可。  
本脚本没有自带循环，因为linux平台几乎都有Crontab（计划任务），利用计划任务可以实现开机启动、循环执行脚本、并设定循环频率而无需常驻后台。  
#### 命令参考 #####    
- 假设脚本已经填写好参数并加了可执行权限（```chmod +x ./dnspod_ddns.sh```），并位于```/root/dnspod_ddns.sh```:  
新建计划任务输入```crontab -e```  
按a进入编辑模式，输入   
 ```*/10 * * * * /root/dnspod_ddns.sh &> /dev/null```  
意思是每隔10分钟执行/root/dnspod_ddns.sh并屏蔽输出日志。当然，如果你需要记录日志可以直接重定向至保存路径。 
然后按Esc，输入:wq回车保存退出即可。  
更多关于Crontab的使用方法此处不再详述。  
- 另外对于一些带有Web管理界面嵌入式系统（比如群晖），有图形化的计划任务菜单管理，可以直接把脚本粘贴进去。  
- 部分系统(比如openwrt)有热插拔接口(hotplug)，把脚本放到hotplug目录即可实现网卡IP变动后触发执行脚本，按需运行。  
以openwrt为例，复制脚本到在/etc/hotplug.d/iface目录下，重命名为`99-ddns`这样，`chmod +x 99-ddns`加上可执行权限，这样脚本就会按需执行，网卡IP变动自动触发。  

#### 工作过程
1、用CHECKURL检查自己的外网ip和本地解析记录是否相同，相同则退出；  
2、使用API获取域名在Dnspod平台的IP记录，如果CHECKURL（line.sh则是直接获取网卡ip）获取IP结果和“本地DNS解析记录或者API记录”相同则退出；获取记录异常也会退出并返回错误信息（例如域名不存在No Record）；  
3、执行DNS更新，并返回执行结果。
#### 注意事项
本脚本**不会**自动创建子域名，请务必先到后台添加一个随意的子域名A记录，否则会提示No Record 

### **dnspod_ddns_line.sh**
仅说明与上面脚本参数不同的地方。  
因该脚本是用于获取网卡设备ip，所以没有CHECKURL参数。  
#### 参数说明
参数|填写说明
:-:|:-
|DEV | 从网卡设备（例如eht0）上获取ip，并与DNS记录比对更新。推荐使用```ip a```命令```ifconfig```命令查看网卡设备名称。  

### 日志参考
现象|说明
:-|:-
[DNS IP]为Get Domain Failed|本地DNS解析出现问题（断网、DNS服务器不工作、域名记录错误）
[URL IP]为空|访问CHECKURL失败，检查网络访问CHECKURL是否正常
No Record|不存在该域名或者该主机记录（本脚本**不会**自动创建子域名，请务必先到后台添加一个随意的子域名A记录）
API usage is limited|调用API频率过高账号被冻结（一小时后解封），正常使用一般不会出现
[URL IP]或者[DEV IP] 和[DNS IP]不一样但和[API IP]一样|DNS有缓存，DNS记录是已经更新，属正常现象，会提示IP SAME IN API,SKIP UPDATE.自动忽略
API更新前后结果一样[IP->IP]|你可能做了自动分流导致CHECKURL得到的结果不一样。

### **关于**
https://blog.03k.org/post/dnspod-ddns-with-bashshell.html
