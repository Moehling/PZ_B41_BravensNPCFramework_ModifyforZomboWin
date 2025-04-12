
# PZ_B41_BravensNPCFramework_ModifyforZomboWin
> [EN] A modified version of Braven's NPC Framework for Zomboid's ZomboDefeat mod  
> [CN] 为《僵尸毁灭工程》ZomboDefeat模组定制的BravenNPC框架修改版

---

## ❗ 免责声明 | Disclaimer
[EN] **This is a direct modification of BitBraven's source files**, not a standalone mod. Initially intended for personal use only.  
[CN] **直接修改了BitBraven的源代码**，并非独立模组。最初仅作为自用修改。

[EN] 📌 *Not recommended for production environments due to potential compatibility issues*  
[CN] 📌 *因可能存在兼容性问题，不建议用于正式环境*

---

## 📜 更新历史 | Changelog

### 1. Beta 版本 | Beta Releases
| #  | [EN] Change | [CN] 变更描述 |
|----|------------|--------------|
| 1  | Sandbox parameter customization | 沙盒参数自定义 |
| 2  | Added genetic outfit selection | 新增基因着装选择 |
| 3  | New surrender dialogues | 添加投降特殊对话 |
| 4  | Optimized ZomboDefeat crash rate (pre-surrender stealth check) | 优化动画闪退率（投降前隐身检测） |

### 2. Gamma 版本 | Gamma Updates

+ [EN] Major performance optimization (+15% FPS)  
+ [CN] 重大性能优化（帧率提升15%）

! [EN] Fixed critical issues:
- Teleportation clothing loss (basement/space ring)
- NPC standing-death state on reload
- ESC menu save exploit


### 3. 最终版 | Final Release
🆕 **Hot Recovery NPC Feature**  
[EN] Trigger by clicking `Exit to Desktop` → `Cancel`  
[CN] 通过点击`退出桌面`→`取消`触发  
✅ Preserves NPC data | ✅ 保留NPC数据  
⚠️ Old NPC becomes offline player-like entity | ⚠️ 旧NPC变为类离线玩家实体

---

## 🛠️ 使用方法 | Usage

### 安装说明 | Installation

1. [EN] Backup original `BravensNPCFramework` folder  
   [CN] 备份原`BravensNPCFramework`文件夹

2. [EN] Choose either:  
   - Overwrite original files  
   - Rename folder (disable original mod)

   [CN] 任选其一：  
   - 覆盖原文件  
   - 重命名文件夹（需禁用原模组）


### 关键功能 | Key Features
| 功能 | [EN] Description | [CN] 说明 |
|------|----------------|----------|
| 投降系统 | `Surrender` emote triggers NPC yield | 表情触发NPC投降 |
| NPC召唤 | `ComeHere` teleports distant NPCs (35+ tiles) | 召唤35格外NPC |
| 濒死机制 | Configurable near-death thresholds | 可调濒死参数 |

---

## ⚠️ 已知问题 | Known Issues

- [EN] Conflict with `MyLittleBraven` mod (duplicate features)  
  [CN] 与`MyLittleBraven`模组冲突（功能重复）

- [EN] Clothing mods may require disabling `HardFix`  
  [CN] 服装模组需关闭`硬修复`选项

- [EN] Possible crashes during zombie animations  
  [CN] 僵尸动画期间可能闪退


---

## 📝 开发者备注 | Developer Notes
> [EN] "This was a 2-week experiment that unexpectedly gained popularity.  
> Some design choices may seem odd - feel free to improve them!"  
>  
> [CN] "本为两周的实验性修改，意外受到欢迎。  
> 部分设计可能欠妥，欢迎改进！"

[EN] 🎮 *Happy zombie surviving!*  
[CN] 🎮 *祝您僵尸求生愉快！*

---
以上由deepseek整理生成，以下是我的文本
---
The above is organized by Deepseek, and the following is my text
---

# PZ_B41_BravensNPCFramework_ModifyforZomboWin
为了玩僵尸击败模组，我思考了一会儿，开始修改它。

In order to enjoy the zombie defeat mod, I pondered for a while and started modifying it. 
***
首先，我很抱歉，我直接修改了BitBraven的源文件，而不是作为扩展而创建一个新的mod。
因为最初我没想制作模组，我只是想修改它们并为自己使用。
但当我发布一个简单的视频时，我发现仍然有人喜欢它。
但已经太晚了，我做了很多修改，我不敢花时间分解它们。

Firstly, I am very sorry that I made modifications directly to the source file of BitBraven instead of creating a new mod for extension. 
Because initially I didn't want to make mods, I just wanted to modify them and use them for myself. 
But when I released a simple video, I found that there were still people who liked it. 
But it's already too late, I've made a lot of modifications, and I dare not take the time to break them down. 
***
## 历史更新与使用方法 Historical Updates and Usage Methods

***
### 历史更新 Historical Updates

#### 一、Beta 更新 Beta Update 
1. 沙盒设置参数自定义 Sandbox setting parameter customization 
2. 追求基因着装 Pursuing genetic dressing 
3. 添加特殊对话 Add special dialogue 
4. 加入投降机制Join surrender mechanism 
5. 投降前判断隐身逃跑，尝试减少ZomboDefeat动画闪退 Before surrendering, determine stealth 和 escape, 和 try to reduce ZomboDefeat animation crashes
---
#### 二、Gamma 更新 Gamma Update
1. 参数调整，增加随机性，减少性能消耗，提高帧率，表现为偶尔npc脑子慢，不愿干等 Parameter adjustment, increased randomness, reduced performance consumption, increased frame rate, manifested as occasional NPC slow brain 和 unwillingness to work, etc 
2. 空手与手持远程投降距离交换,其他小机制、小行为调整 Empty handed 和 handheld remote surrender distance exchange, other small mechanisms 和 behavior adjustments 
3. 修复理解性错误，无恙 Fixed comprehension errors, unharmed 
4. 修复传送问题，如地下室、空间戒指等地图传送造成替换服装与初始服装丢失或传送一次就在背包生成一个初始服装的问题 Fix teleportation issues, such as map teleportation in basements, space rings, etc. causing replacement clothing to be lost from the initial clothing or generating an initial clothing in the backpack after one teleportation. 
5. 修复原esc菜单仅仅点击“退出到桌面”，就能刷出缓存箱来准备保存，改为点击退出到桌面后弹出确认菜单，点“确认”才进行保存 Fixed the original ESC menu where only clicking "Exit to Desktop" could flush out the cache box to prepare for saving. Instead, click "Exit to Desktop" to pop up a confirmation menu 和 click "Confirm" to save
6. 修复npc濒死时退出存档，后继续游戏该npc会一直处于站立濒死状态且难以恢复 Fixed the situation where an NPC exits the save when it is on the brink of death, 和 if it continues to play, the NPC will remain in a standing 和 dying state, making it difficult to recover. 
7. 识别q菜单comehere，允许超出地图视野或距离较远的npc传送一个过来 Identify the 'comehere' menu 和 allow NPCs that are beyond the map's field of view or far away to send one over. 
8. 当npc是重要角色时，血量低会进入濒死（被推坐在地，无法回应玩家，不能做出任何动作），原版的是濒死隐身。非重要角色仍会死亡，尸体复活为僵尸，后重生。注意：因不会隐身故容易闪退，建议将僵尸抓取范围调为中、小 When the NPC is an important character, low health will lead to near death (being pushed to the ground, unable to respond to the player, unable to make any movements), while the original version is near death invisibility. Non essential characters will still die, their bodies will be resurrected as zombies, and then reborn. Attention: Due to the inability to become invisible, it is easy to flash back. It is recommended to adjust the zombie grasping range to medium or small 
9. 可自定义濒死血线、恢复读秒、濒死是否无敌 Customizable near death blood lines, recovery reading seconds, 和 whether near death is invincible

---
#### 三、最终 Release 更新 Final Release Update
1. 对gamma版本的简单修复 Simple fix for gamma version 
2. 增加热恢复npc功能，点击主菜单“退出到桌面”按钮，后点“取消”按钮，npc会保存数据并新建npc载入数据到你身边，之前的npc会丢失ai，丢失ai的npc看起来就像是离线的玩家，属性数据不与新npc共享，但仍会执行基本脚本逻辑，如被僵尸简单的抓取并进入动画等。如若卡顿，可走出地图边界，便能刷掉npc。 Add the hot recovery NPC function. Click the "Exit to Desktop" button in the main menu, and then click the "Cancel" button. The NPC will save the data and create a new NPC to load the data to you. The previous NPC will lose its AI, and the NPC that loses AI will look like an offline player. The attribute data will not be shared with the new NPC, but it will still execute basic script logic, such as being easily captured by zombies and entering animations. If stuck, you can step out of the map boundary and brush off the NPC.

---
### 使用方法与一些细节 Usage and some Details

1. 您可以选择覆盖BravensNPCFramework文件，也可以选择将文件夹名改一点然后并列放置但不要启用原mod，虽然我直接修改了源码，而且也更改了modID和其他信息，即便如此也肯定有冲突 You can choose to overwrite the BravensNPCFramework file, or you can choose to change the folder name a bit 和 place it side by side without enabling the original mod, even though I directly modified the source code 和 also changed the mod ID 和 other information. Even so, there will definitely be conflicts 
2. MyLittleNPC mod与MyLittleBraven mod冲突，因为已经包含了 MyLittleNPC mod conflicts with MyLittleBraven mod as it already includes 
3. 如果安装了服装幻化mod，那么需要关闭硬修复，这可能使非玩家的头部覆盖服装不显示 If the clothing illusion mod is installed, hard repair needs to be turned off, which may cause non players' head covering clothing to not display 
4. 初始服装的设定需要使用任意服装mod下script文件夹内文件的item标识符，代码中只检查衣服，所以您写其他的并不会获得什么 The initial clothing settings require the use of item identifiers from files in the script folder under any clothing mod. The code only checks the clothes, so writing anything else will not result in anything. 
5. 玩家的表情我添加了“投降”和“过来”，“投降”就不讲了，“过来”是传送一个超过35格的npc过来 I added "surrender" 和 "comehere" to the player's expressions. "surrender" is not mentioned, "comehere" is to teleport an NPC with more than 35 squares over 
6. 还有一些细节或问题，但是我忘了，您可以自行探索出问题，并尝试解决，如果解决不了可以使用热恢复功能。 There are still some details or bugs, but I forgot. You can explore the problem yourself and try to solve it. If you can't solve it, you can use the hot recovery function.

---
这就是我这两周做的所有了，可能吧？哈哈！

That's all I've done in the past two weeks, maybe? ha-ha?
