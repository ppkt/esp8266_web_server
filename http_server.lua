print(wifi.sta.getip())

dht_pin = 2; -- IO4
sda_pin = 5;
scl_pin = 6;

bmp180 = require("bmp180_2") 

bmp180.init(sda_pin, scl_pin)
            
srv = net.createServer(net.TCP)
srv:listen(80, function(conn)
    conn:on("receive", function(client, request) 
        local buf = "";
        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
        --print(vars)
        --print(method)
        --print(path)
        if(method == nil)then
            _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
        end
        --print(method)
        --print(path)
        --local _GET = {}
        --if (vars ~= nil)then
        --    for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
        --        _GET[k] = v
        --    end
        --end
        --for k, v in pairs(_GET) do
        --   print(k, v)
        --end

        local response = {}

        --TODO: move reading to separate "thread"
        response['header'] = "ESP8266 ppkt Web Server";
        if (path == "/humidity") then
            local status, temperature, humidity, _, _ = dht.readxx(dht_pin)
            if (status == dht.OK) then
                response['humidity'] = humidity
                response['temperature'] = temperature
                response['error'] = 0
                print("DHT Reading successful. T:"..temperature.." H:"..humidity);
            elseif( status == dht.ERROR_CHECKSUM ) then
                response['error'] = 1
                print("DHT Checksum error.");
            elseif( status == dht.ERROR_TIMEOUT ) then
                response['error'] = 2
                print("DHT Time out.");
            end
        elseif (path == "/pressure") then
            bmp180.read(3)
            t = math.floor(bmp180.getTemperature())
            p = math.floor(bmp180.getPressure())
            
            -- temperature in degrees Celsius
            print("Temperature: "..(t/10).." deg C")
            response["temperature"] = t / 10;
            
            -- pressure in differents units
            response["pressure"] = p;
            print("Pressure: "..(p).." Pa")
        elseif (path == "/") then
            response["pressure_readings"] = "/pressure";
            response["humidity_readings"] = "/humidity";
            response["root"] = "/";
        end

        buf = buf .. "HTTP/1.0 200 OK\r\n"
        buf = buf .. "Content-Type: application/json; charset=us-ascii\r\n"
        local reply = cjson.encode(response)
        buf = buf .. "Content-Length: " .. string.len(reply) .. "\r\n"
        buf = buf .. "\r\n"
        buf = buf .. reply
        
        client:send(buf);
        client:close();
        collectgarbage();
    end )
end )

