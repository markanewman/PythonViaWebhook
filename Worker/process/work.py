import time

def init():
    time.sleep(60)
    return {'v1': 0}

def execute(state, file_path_in, file_path_out):
	with open(file_path_in, 'r', encoding = 'utf-8') as file_in:
		with open(file_path_out, 'a', encoding = 'utf-8') as file_out:
			file_out.write(str(state['v1']))
			file_out.write('---')
			file_out.write(file_in.read())
