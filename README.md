# PZ_B41_BravensNPCFramework_ModifyforZomboWin
In order to enjoy the zombie defeat mod, I pondered for a while and started modifying it. 
***
Firstly, I am very sorry that I made modifications directly to the source file of BitBraven instead of creating a new mod for extension. 
Because initially I didn't want to make mods, I just wanted to modify them and use them for myself. 
But when I released a simple video, I found that there were still people who liked it. 
But it's already too late, I've made a lot of modifications, and I dare not take the time to break them down. 
***
## 历史更新与使用方法


***
### 历史更新

#### 一、Beta 更新
1. 沙盒设置参数自定义
2. 追求基因着装
3. 添加特殊对话
4. 加入投降机制
5. 投降前判断隐身逃跑，尝试减少ZomboDefeat动画闪退
---
#### 二、Gamma 更新
1. 参数调整，增加随机性，减少性能消耗，提高帧率，表现为偶尔npc脑子慢，不愿干等
2. 空手与手持远程投降距离交换,其他小机制、小行为调整
3. 修复理解性错误，无恙
4. 修复传送问题，如地下室、空间戒指等地图传送造成替换服装与初始服装丢失或传送一次就在背包生成一个初始服装的问题
5. 修复原esc菜单仅仅点击“退出到桌面”，就能刷出缓存箱来准备保存，改为点击退出到桌面后弹出确认菜单，点“确认”才进行保存
6. 修复npc濒死时退出存档，后继续游戏该npc会一直处于站立濒死状态且难以恢复
7. 识别q菜单comehere，允许超出地图视野或距离较远的npc传送一个过来
8. 当npc是重要角色时，血量低会进入濒死（被推坐在地，无法回应玩家，不能做出任何动作），原版的是濒死隐身。非重要角色仍会死亡，尸体复活为僵尸，后重生。注意：因不会隐身故容易闪退，建议将僵尸抓取范围调为中、小
9. 可自定义濒死血线、恢复读秒、濒死是否无敌
---
#### 三、最终 Release 更新
1. 对gamma版本的简单修复
2. 增加热恢复npc功能，点击主菜单“退出到桌面”按钮，后点“取消”按钮，npc会保存数据并新建npc载入数据到你身边，之前的npc会丢失ai，丢失ai的npc看起来就像是离线的玩家，属性数据不与新npc共享，但仍会执行基本脚本逻辑，如被僵尸简单的抓取并进入动画等。如若卡顿，可走出地图边界，便能刷掉npc。

---
### 使用方法与一些细节

1. 您可以选择覆盖BravensNPCFramework文件，也可以选择将文件夹名改一点然后并列放置但不要启用原mod，虽然我直接修改了源码，而且也更改了modID和其他信息，即便如此也肯定有冲突
2. MyLittleNPC mod与MyLittleBraven mod冲突，因为已经包含了
3. 如果安装了服装幻化mod，那么需要关闭硬修复，这可能使非玩家的头部覆盖服装不显示
4. 初始服装的设定需要使用任意服装mod下script文件夹内文件的item标识符，代码中只检查衣服，所以您写其他的并不会获得什么
5. 还有一些细节，但是我忘了，您可以自行探索出问题，并尝试解决，如果解决不了可以使用热恢复功能。

这就是我这两周做的所有了，可能吧？哈哈！

That's all I've done in the past two weeks, maybe? ha-ha?
