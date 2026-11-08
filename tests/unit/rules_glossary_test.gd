extends GdUnitTestSuite

func test_links_terms_and_their_forms() -> void:
	assert_str(RulesGlossary.link("Lose at most your [b]1[/b] highest breath die.")).is_equal(
		"Lose at most your [b]1[/b] highest [url=glossary:breath die]breath die[/url].")
	assert_str(RulesGlossary.link("[b]+1[/b] to all attributes.")).is_equal("[b]+1[/b] to all [url=glossary:attribute]attributes[/url].")

func test_links_attributes_inside_tags() -> void:
	assert_str(RulesGlossary.link("When you pass a [b]Guts[/b] save")).is_equal(
		"When you pass a [b][url=glossary:guts]Guts[/url][/b] [url=glossary:save]save[/url]")

func test_leaves_hints_and_links_alone() -> void:
	var text: String = "you find [hint=\"a breath die\"][i]a save[/i][/hint], [url=x]vantage[/url] and vantage"
	assert_str(RulesGlossary.link(text)).is_equal(
		"you find [hint=\"a breath die\"][i]a save[/i][/hint], [url=x]vantage[/url] and [url=glossary:vantage]vantage[/url]")

func test_only_whole_words() -> void:
	assert_str(RulesGlossary.link("Saved, unsaved, vantages")).is_equal("Saved, unsaved, vantages")

func test_tooltips() -> void:
	assert_array(RulesGlossary.tooltip_for("glossary:vantage")).is_equal([RulesGlossary.TERMS["vantage"]])
	assert_array(RulesGlossary.tooltip_for("glossary:guts")).is_equal([RulesGlossary.describe_attribute(Rules.STRENGTH)])
	assert_array(RulesGlossary.tooltip_for("x")).is_empty()
