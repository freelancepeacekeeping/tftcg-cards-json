import json
import os
import re
import copy

from airtable import Airtable

# Grab the cards, save them as JSON
def airtable_to_json_file(id, api_key, table_name, file_name, mutator = None):
    # Open a connection to Airtable
    at = Airtable(id, table_name, api_key=api_key)
    cards = at.get_all()
    if(mutator):
        cards = mutator(cards)
    data = { "records" : cards }
    json_file=open(file_name, 'w+')
    json_file.write(json.dumps(data, indent=2))
    json_file.close()

# Fix the Wave 4 Weaponizers so they have two entries instead of one
def bot_mutate(cards):
    for card in cards:
        # If Card # contains an &, then split it into two cards
        if('&' in card['fields']['Card #']):
            # Copy the card
            copied_card=copy.deepcopy(card)
            # Fix the copy's Card #
            copied_card['fields']['Card #'] = re.sub(r"T..&", '', copied_card['fields']['Card #'])
            # Fix the copy's images
            copied_card['fields']['Image(s)'] = [ copied_card['fields']['Image(s)'][2], copied_card['fields']['Image(s)'][1] ]
            # Add the copy
            cards.append(copied_card)
            # Fix the original's Card #
            card['fields']['Card #'] = re.sub(r"&T..", '', card['fields']['Card #'])
            # Fix the original's images
            card['fields']['Image(s)'] = [ card['fields']['Image(s)'][2], card['fields']['Image(s)'][0] ]
    return cards

# Load the airtable key from disk
key_file=open('airtable.key', 'r')
key=key_file.read().rstrip(os.linesep)
key_file.close()

# ID for the transformers.cards application
transformers_card_id='appVjmNG3AukyOaQn'

# Grab cards
airtable_to_json_file(transformers_card_id, key, 'Bot Cards', 'json/bot-cards.json', bot_mutate)
airtable_to_json_file(transformers_card_id, key, 'Battle Cards', 'json/battle-cards.json')
airtable_to_json_file(transformers_card_id, key, 'Combiner Forms', 'json/combiner-forms.json')
