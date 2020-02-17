require 'json'
require 'bucket_match'
require 'rexml/document'

include REXML

def index_tcards_json(json)
  hash = Hash.new
  json['records'].each do |record|
    name = record['fields']['Name']
    if record['fields']['Subtitle']
      name = name + ' - ' + record['fields']['Subtitle']
    end
    hash[name] = record
  end

  return hash
end

# Read .o8d file in
o8d_file = ARGV[0]

# parse the XML
xmldoc = Document.new(File.new(o8d_file))
root = xmldoc.root

deck_title = o8d_file.gsub(/^.*\//, '').gsub(/\.o8d$/, '').gsub(/(.)([A-Z])/, '\1 \2')

# TODO: Currently there is a bug in that the o8d format uses the Battlemaster's upgrade mode, not their bot mode.
#       This means that the data matches to the wrong pricing/database values. 
#       Somehow need to match against the Battlemaster names too. That will mean matching against the 
#       database first, then using the data found there to match against the pricing. 

# Read in the main database jsons
combiner_forms_raw=JSON.parse(File.read(File.expand_path('../json/combiner-forms.json', __dir__)))
battle_cards_raw=JSON.parse(File.read(File.expand_path('../json/battle-cards.json', __dir__)))
bot_cards_raw=JSON.parse(File.read(File.expand_path('../json/bot-cards.json', __dir__)))

# Index these jsons
combiner_forms = index_tcards_json(combiner_forms_raw)
battle_cards = index_tcards_json(battle_cards_raw)
bot_cards = index_tcards_json(bot_cards_raw)

# Read in pricing json
pricing=JSON.parse(File.read(File.expand_path('../pricing/pricing.json', __dir__)))


##################### EXAMPLE ############################
# <?xml version="1.0" encoding="utf-8" standalone="yes"?>
# <deck game="f44befce-4d6d-4fb9-a286-9585f36aece9">
#   <section name="Characters" shared="False">
#    <card qty="N" id="UUID">Title - Subtitle</card>
#    ...
#   </section>
#   <section name="Deck" shared="False">
#    <card qty="N" id="UUID">Title</card>
#    ...
#   </section>
#   <section name="Sideboard" shared="False">
#    <card qty="N" id="UUID">Title - Subtitle</card>
#    <card qty="N" id="UUID">Title</card>
#    ...
#   <notes><![CDATA[]]></notes>
# </deck>
##########################################################
#
# Planned JSON format:
#
# { "title" : "...",
#   "Characters" : [
#     {
#       "quantity" : n,
#       "title" : "..."
#     },
#     {
#       "quantity" : n,
#       "title" : "..."
#     },
#     ...
#   ],
#   "Deck" : [
#     ...
#   ],
#   "Sideboard" : [
#     ...
#   ],
#   "Notes" : "..."
# }
#
#   QUERY: Should cards know their type? As a way to split the Sideboard apart?

OCTGN_TRANSFORMER_UUID='f44befce-4d6d-4fb9-a286-9585f36aece9'

if root.attribute('game').value != OCTGN_TRANSFORMER_UUID
  puts "WARNING: Deck does not appear to be using the expected Transformer UUID (Using #{root.attribute('game')} instead of #{OCTGN_TRANSFORMER_UUID})"
end

card_names = []

XPath.each(xmldoc, '//card') do |card|
    card_names << card.text
end

# Match the deck's card names with the pricing names
pricing_names = pricing['data'].keys
database_combiner_titles = combiner_forms.keys
database_bot_titles = bot_cards.keys
database_battle_titles = battle_cards.keys

# Combiner forms don't have prices. We add them to the mapping so they won't false positive
pricing_mapping = BucketMatch::match(card_names, pricing_names.concat(database_combiner_titles))

# Match the deck's card names with the database names
database_mapping = BucketMatch::match(card_names, database_combiner_titles.concat(database_bot_titles).concat(database_battle_titles))

json_output = Hash.new
json_output['Title'] = deck_title

root.each_element('section') do |section|
  name=section.attribute('name')
  cards = Array.new
  json_output[name] = cards

  section.each_element('card') do |card|
    json_card = Hash.new
    json_card['title'] = card.text
    json_card['quantity'] = card.attribute('qty').value

    # Get the pricing from the pricing json
    price_entry = pricing['data'][pricing_mapping[card.text]]
    if price_entry
      json_card['price'] = price_entry[1]
    end

    # Get the card data details from the database jsons
    database_entry_name = database_mapping[card.text]

    # TODO: Potential bug if a card and character have the same name
    if combiner_forms[database_entry_name]
      json_card['details'] = combiner_forms[database_entry_name]
    elsif battle_cards[database_entry_name]
      json_card['details'] = battle_cards[database_entry_name]
    elsif bot_cards[database_entry_name]
      json_card['details'] = bot_cards[database_entry_name]
    end

    cards << json_card
  end
end

rarity_enum = { 'Common' => 0, 'Uncommon' => 1, 'Rare' => 2, 'Super-Rare' => 3 }

json_output.each() do |key, value|

#  if(value.respond_to?('sort'))
  if(value.kind_of?(Array))
    json_output[key] = value.sort do |a, b|
      if a['details']['fields'].has_key?('Component Bots') and b['details']['fields'].has_key?('Component Bots')
        # Combiners lack sets or rarity
        a['title'] <=> b['title']
      elsif a['details']['fields'].has_key?('Component Bots')
        0
      elsif b['details']['fields'].has_key?('Component Bots')
        1
      else
        [a['details']['fields']['Set'], rarity_enum[a['details']['fields']['Rarity']], a['title']] <=>
        [b['details']['fields']['Set'], rarity_enum[b['details']['fields']['Rarity']], b['title']]
      end
    end
  end
end

root.each_element('notes') do |notes|
  json_output['Notes'] = notes.text   # TODO: Concat if multiple notes
end

puts JSON.pretty_generate(json_output)
