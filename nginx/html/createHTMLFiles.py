for sizeInKiloBytes in [1, 10, 100, 1000]:
    text_file= open('index'+str(sizeInKiloBytes)+'kb.html', 'w')
    text_file.write('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">\n<html>\n<head>\n</head>\n<body>')
    text_file.write('0'*(sizeInKiloBytes*1000-129))
    text_file.write('</body>\n</html>')
    text_file.write('\n')
    text_file.write('\n')
    text_file.close()
