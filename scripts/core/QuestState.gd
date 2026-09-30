extends RefCounted
class_name QuestState

const OBJECTIVES := {
	"start": "前往客栈，询问遗失飞剑的线索",
	"ask_tavern": "前往酒馆，打听山谷异动",
	"go_to_mountain": "穿过镇门，前往山谷试炼地",
	"cleanse_seal": "站立施法，驱散小妖并破除封印",
	"collect_sword": "取回祭台上的飞剑",
	"fly_back": "御剑飞回小镇高台",
	"complete": "试炼完成，飞剑已归鞘",
}

const TRANSITIONS := {
	"start": {"talked_to_innkeeper": "ask_tavern"},
	"ask_tavern": {"talked_to_tavern_keeper": "go_to_mountain"},
	"go_to_mountain": {"entered_trial": "cleanse_seal"},
	"cleanse_seal": {"seal_cleansed": "collect_sword"},
	"collect_sword": {"sword_collected": "fly_back"},
	"fly_back": {"returned_to_town": "complete"},
	"complete": {},
}

var current_step := "start"

func current_objective() -> String:
	return OBJECTIVES.get(current_step, "")

func advance(event_id: String) -> bool:
	var options: Dictionary = TRANSITIONS.get(current_step, {})
	if not options.has(event_id):
		return false
	current_step = options[event_id]
	return true
