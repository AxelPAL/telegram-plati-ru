require_relative 'config'
require 'telegram_bot'
require 'awesome_print'
require 'net/http'

bot = TelegramBot.new(token: @telegram_api)
bot.get_updates(fail_silently: true) do |message|
  puts "@#{message.from.username}: #{message.text}"
  command = message.get_command_for(bot)

  message.reply do |reply|
    case command
      when /start/i
        reply.text = "Приветствуем, #{message.from.first_name}! Просто введите то, что хотите найти и отправьте нам."
      else
        query = message.text
        products = []
        links = []
        page_size = 10
        reply.text = 'Товары по вашему запросу не найдены'
        if query
          source = Net::HTTP.get('www.plati.com', "/api/search.ashx?query=#{URI::encode(query)}&pagesize=#{page_size}&response=json")
          data = JSON.parse(source)
          unless data.empty? && data['items'].empty?
            data['items'].each do |row|
              products.push(row)
            end
          end
          products.sort! {|a,b| a['price_rur'].to_f <=> b['price_rur'].to_f}
          if products
            products.each do |product|
              links.push "<a href='#{product['url']}&ai=60697'>#{product['name']} (#{product['price_rur']} руб)</a>\n"
            end
          end
        end
        if links
          reply.text = links.join(' ')
        end
        reply.parse_mode = 'HTML'
    end
    reply.send_with(bot)
    ap message.from
  end
end