import os
import time
BASE_DIR = os.path.dirname(os.path.dirname(__file__))
while True:
	while True:
		f = open(os.path.join(BASE_DIR,'from_perl.txt'),'r+')
		if f is not None:
			break
	
	strs = f.read()
	f.close()
	
	if len(strs) > 2 :
		while True:
			f = open(os.path.join(BASE_DIR,'from_perl.txt'),'w+')
			if f is not None:
				break
			f.write('')
			f.close()
		while True:
			f = open(os.path.join(BASE_DIR,'from_gui.txt'),'w+')
			if f is not None:
				break


		f.write(strs)
		print "Wrote:   to gui from perl"
		f.close()
		while True:
			f = open(os.path.join(BASE_DIR,'states.txt'),'r')
			if f is not None:
				break
		states = f.read()
		print "STates" + states
		index = states.find(strs[0:5])
		index += 5 
		part1 = states[0:index]
		print "part1" + part1
		part2 = states[index+1:len(states)]
		print "Part2:" + part2
		to = strs[5]
		final = part1 +to+part2
		print "Final:" + final
		f.close()
		while True:
			f = open(os.path.join(BASE_DIR,'states.txt'),'w+')
			if f is not None:
				break   
		f.write(final)
		f.close()
	
	time.sleep(3)
	