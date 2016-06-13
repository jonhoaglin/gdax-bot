namespace :gdax do
  desc 'Testing the GDAX API'
      
  task :init => :environment do
    @logger = Logger.new("log/trade_#{Time.now.strftime("%Y%m%d")}.log")
    @logger.info 'Initialize REST API...'
    api_secret = '9NogBs9q6FpcjiaCr2UvSGqoyMO2SJG0QAaXo2t6UjO086qjKET2Oi3jFqXifwcdRmewwj6E26KqWH52iXnDgg=='
    api_key = 'a3088fd2aa7a38371c34db4b68e8c9c1'
    api_pass = 'cntm69lyvkt'
    
    @rest_api = Coinbase::Exchange::Client.new(api_key, api_secret, api_pass, product_id: "BTC-USD")
    
    #Get my account IDs
    @rest_api.accounts do |resp|
      resp.each do |account|
        case account.currency
          when "USD"
            @account_id_usd = account.id
          when "BTC"
            @account_id_btc = account.id
          else
            @account_id_eth = account.id
        end
      end
    end
    @stat = Stat.new(spot: @rest_api.last_trade.price.to_f,
                      usd_avail: @rest_api.account(@account_id_usd).available.to_f,
                      usd_bal: @rest_api.account(@account_id_usd).balance.to_f,
                      btc_avail: @rest_api.account(@account_id_btc).available.to_f,
                      btc_bal: @rest_api.account(@account_id_btc).balance.to_f,
                      eth_avail: @rest_api.account(@account_id_eth).available.to_f,
                      eth_bal: @rest_api.account(@account_id_eth).balance.to_f,
                      move: 0
                      )
    @stat.save
    @time_start = Time.now
  end
    
  task :trade => :init do
    @logger.info "Starting main loop..."
    #Start Main Loop
    while @time_start+3.days > Time.now
      begin
        @stat.attributes = {spot: @rest_api.last_trade.price.to_f,
                            usd_avail: @rest_api.account(@account_id_usd).available.to_f,
                            usd_bal: @rest_api.account(@account_id_usd).balance.to_f,
                            btc_avail: @rest_api.account(@account_id_btc).available.to_f,
                            btc_bal: @rest_api.account(@account_id_btc).balance.to_f,
                            eth_avail: @rest_api.account(@account_id_eth).available.to_f,
                            eth_bal: @rest_api.account(@account_id_eth).balance.to_f}
        @logger.info "#{@stat.spot.round(4)} USD current : #{@stat.usd_avail.round(4)} USD available : #{@stat.btc_avail.round(4)} BTC available : #{@stat.total.round(4)} USD total value"
        
        #price history 
        @rest_api.price_history(start: 10.seconds.ago, granularity: 30) do |resp|
          candles = resp.map { |candle| candle.close - candle.open }
          @stat.move = candles.inject(:+).to_f / candles.length
        end
        @logger.info "#{@stat.move.round(4)} USD movement last 10s"
        
        if @stat.move >= 0 #if price is going up
          if @stat.spot/100+@stat.fee <= @stat.usd_avail #if can afford
            #place buy order
            @rest_api.buy(0.01, @stat.spot) do |resp|
              @logger.info "Placing Buy Order ID: #{resp.id}"
              puts "Placing Buy Order ID: #{resp.id}"
              @status = "open"
              @waittime = Time.now
              while @status != "done"
                @rest_api.order(resp.id) do |respect|
                  @status = respect.status
                  if @status == "done"
                    @fee = respect.fill_fees.to_f
                    @price = respect.price.to_f
                    @cancelled = false
                  elsif @waittime+2.minutes > Time.now
                    @rest_api.cancel(resp.id) do
                      @logger.info "Order canceled successfully"
                      @cancelled = true
                    end
                  end
                end
              end
              unless @cancelled
                Order.create(currency: "BTC-USD",
                            buy_id: resp.id,
                            buy: @price,
                            quantity: 0.01,
                            fees: @fee,
                            ledger: @stat.total)
              end
            end
          end
        else #price is going down
          Order.where(sell: nil).each do |order| #check price of past orders
            if @stat.spot-(@stat.fee*2) >= (order.buy)
              #place sell order
              @rest_api.sell(order.quantity, @stat.spot) do |resp|
                @logger.info "Placing Sell Order ID: #{resp.id}"
                puts "Placing Sell Order ID: #{resp.id}"
                @status = "open"
                @waittime = Time.now
                while @status != "done"
                  @rest_api.order(resp.id) do |respect|
                    @status = respect.status
                    if @status == "done"
                      @fee = respect.fill_fees.to_f
                      @price = respect.price.to_f
                      @cancelled = false
                    elsif @waittime+2.minutes > Time.now
                      @rest_api.cancel(resp.id) do
                        @logger.info "Order canceled successfully"
                        @cancelled = true
                      end
                    end
                  end
                end
                unless @cancelled
                  order.attributes = {sell: @price,
                                      sell_id: resp.id,
                                      fees: order.fees+@fee,
                                      ledger: @stat.total}
                  order.save
                end
              end
            end
          end
        end
        @stat.save
        sleep 10 #maximum 3 requests per second
      rescue
        @logger.error "ERROR occured"
        @logger.error $!
        puts "ERROR occured"
        puts $!
        next
      end
    end
  end
end
