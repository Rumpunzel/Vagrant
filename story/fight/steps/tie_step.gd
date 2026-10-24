class_name TieStep
extends ExchangeStep

## Equal threats: nobody gives way, so every stance works with its full threat. Concerns both sides; [member side] is not used.

func applies(fight: Fight) -> bool: return fight.get_last_exchange().first.threat == fight.get_last_exchange().second.threat

func enter(fight: Fight) -> String:
	return "Neither of you gives way at %d: both stances strike with the full threat!" % fight.get_last_exchange().first.threat
