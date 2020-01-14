require 'json'
require 'bucket_match'
require 'rexml/document'

include REXML

# Read .o8d file in
o8d_file = ARGV[0]

# parse the XML
xmldoc = Document.new(File.new(o8d_file))
root = xmldoc.root

deck_title = o8d_file   # TODO: Convert this to a more readable format

# Read in the main database jsons
combiner_forms=JSON.parse(File.read('../json/combiner-forms.json'))
battle_cards=JSON.parse(File.read('../json/battle-cards.json'))
bot_cards=JSON.parse(File.read('../json/bot-cards.json'))

# Read in pricing json
pricing=JSON.parse(File.read('../pricing/pricing.json'))


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

json_output = Hash.new
json_output['Title'] = deck_title
card_names = []

root.each_element('section') do |section|
  name=section.attribute('name')
  cards = Array.new
  json_output[name] = cards
  
  section.each_element('card') do |card|
    json_card = Hash.new
    json_card['title'] = card.text
    card_names << card.text
    json_card['quantity'] = card.attribute('qty').value
    cards << json_card
  end
end

root.each_element('notes') do |notes|
  json_output['Notes'] = notes.text   # TODO: Concat if multiple notes
end

# Match the deck's card names with the pricing names
pricing_names = pricing['data'].map { |row| row[0] }
database_combiner_titles = combiner_forms['records'].map { |row| row['fields']['Name'] + " - " + row['fields']['Subtitle'] }
database_bot_titles = bot_cards['records'].map { |row| row['fields']['Name'] + " - " + row['fields']['Subtitle'] }
database_battle_titles = battle_cards['records'].map { |row| row['fields']['Name'] }

# Combiner forms don't have prices. We add them to the mapping so they won't false positive
pricing_mapping = BucketMatch::match(card_names, pricing_names.concat(database_combiner_titles))

p pricing_mapping

# Match the deck's card names with the database names
database_mapping = BucketMatch::match(card_names, database_combiner_titles.concat(database_bot_titles).concat(database_battle_titles))
p database_mapping
