puts "1"
sleep 1
puts "2"

Signal.trap("TERM") do
  puts "TERM"
  sleep 1
  exit 3
end

sleep 10
puts "3"
exit 4
