# TODO - PID is currently hard-coded

while :; 
	do clear; 
	lldb -o "thread backtrace all" --batch -p 71468 >> temp.txt
	sleep 10; 
done

#watch -n 10 'lldb -o "thread backtrace all" --batch -p 71468'
