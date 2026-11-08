class_name RulesGlossary
extends RefCounted

## Rules terms in game texts (abilities), each linked ([code][url][/code]) to a short explanation shown as its tooltip
## ([method tooltip_for] for a [MetaTooltipTrigger]).

const META_PREFIX: String = "glossary:"
## Term (lower case) -> what it means; the attributes come from [constant Rules.ATTRIBUTES]
const TERMS: Dictionary[String, String] = {
	"breath die": "[b]Breath dice[/b] (d4 to d12) are your effort and exhaustion, rolled for saves and fights. One that comes up above the attribute it was rolled with is lost. "
		+ "Catching your breath exhausts one die type to recover all the others; making camp ends exhaustion.",
	"weapon die": "A weapon's [b]die[/b] is rolled with your breath dice in a fight's exchange; it strikes for damage. Above the attribute it is wielded with, it has to be forced: that costs threat and marks the weapon.",
	"vantage": "Who threatens more in a fight's exchange wins the [b]vantage[/b], the difference between both threats; their stance turns it into more damage dealt (Guts), less damage taken (Blood) or an unnerved foe (Nerves).",
	"save": "A [b]save[/b] rolls the breath dice you choose: the highest result at or above the difficulty passes.",
	"attribute": "Your three [b]attributes[/b], Guts, Blood and Nerves, are rolled with 2d6 each. Injuries lower all of them.",
}
## Other forms of a term in [constant TERMS]
const FORMS: Dictionary[String, String] = {
	"breath dice": "breath die",
	"weapon dice": "weapon die",
	"saves": "save",
	"attributes": "attribute",
}

static var _pattern: RegEx

## [param bbcode] with each rules term in its plain text linked; not inside tags, links or hints
static func link(bbcode: String) -> String:
	var linked: String = ""
	var skipping: int = 0
	var start: int = 0
	for tag: RegExMatch in _tags().search_all(bbcode):
		if skipping == 0: linked += _link_plain(bbcode.substr(start, tag.get_start() - start))
		else: linked += bbcode.substr(start, tag.get_start() - start)
		var tag_name: String = tag.get_string(2).to_lower()
		if tag_name == "url" or tag_name == "hint": skipping += -1 if tag.get_string(1) == "/" else 1
		linked += tag.get_string()
		start = tag.get_end()
	linked += _link_plain(bbcode.substr(start)) if skipping == 0 else bbcode.substr(start)
	return linked

## The explanation of a link made by [method link]; nothing for other links
static func tooltip_for(meta: Variant) -> Array[String]:
	var link_meta: String = str(meta)
	if not link_meta.begins_with(META_PREFIX): return []
	var term: String = link_meta.trim_prefix(META_PREFIX)
	if TERMS.has(term): return [TERMS[term]]
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		if attribute.descriptor.to_lower() == term: return [describe_attribute(attribute)]
	return []

static func describe_attribute(attribute: CharacterAttribute) -> String:
	return TooltipText.compose("%s [b]%s[/b]" % [attribute.to_bbcode(), attribute.descriptor], attribute.details)

static func _link_plain(text: String) -> String:
	var linked: String = ""
	var start: int = 0
	for term: RegExMatch in _terms().search_all(text):
		var found: String = term.get_string().to_lower()
		linked += text.substr(start, term.get_start() - start)
		linked += "[url=%s%s]%s[/url]" % [META_PREFIX, FORMS.get(found, found), term.get_string()]
		start = term.get_end()
	return linked + text.substr(start)

static func _tags() -> RegEx:
	return RegEx.create_from_string("\\[(/?)(\\w+)[^\\]]*\\]")

static func _terms() -> RegEx:
	if _pattern: return _pattern
	var terms: Array[String] = []
	terms.append_array(TERMS.keys())
	terms.append_array(FORMS.keys())
	for attribute: CharacterAttribute in Rules.ATTRIBUTES: terms.append(attribute.descriptor.to_lower())
	# Longest first, so "breath dice" isn't taken for a shorter term
	terms.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	_pattern = RegEx.create_from_string("(?i)\\b(%s)\\b" % "|".join(terms))
	return _pattern
