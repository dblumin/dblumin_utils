import click


@click.command()
@click.option('--error_delimeter', default='WARNING,ERROR', show_default=True, help='''Word, or 
comma-separated list of words, that denotes the error(s) to extract.''')
@click.option('--filelist', default='filelist.txt', show_default=True, help='''Text file containing the path to all 
files to process. One file per line.''')
def main(error_delimeter, filelist):
    error_dictionary = {}
    symbol_dictionary = {}
    error_types = []
    with open(filelist, 'r') as file_list, open('summary.csv', 'w+') as output_file, open('invalid_symbols.csv', 'w+') as symbol_file:
        output_file.seek(0)
        output_file.truncate(0)
        output_file.write('#TYPE,INSTANCE,VENUE,DATE,COUNT,GREP_FILE,EXAMPLE')
        symbol_file.seek(0)
        symbol_file.truncate(0)
        symbol_file.write('#SYMBOL,VENUE,DATE')
        # comma denotes error delimeter contains multiple delimeters to look for
        for error_delimeter in error_delimeter.split(','):
            file_list.seek(0)

            # for each file in filelist
            for list_line in file_list.readlines():
                input_file = list_line.rstrip()
                split_file = input_file.split('-')
                if len(split_file) > 1:
                    first_half = split_file[0]
                    loader = first_half[len(first_half) - 1]
                else:
                    split_file = input_file.split('.')
                    first_half = split_file[0]
                    loader = first_half[len(first_half) - 1]
                with open(input_file, 'r') as log_file:
                    error_dictionary[error_delimeter] = {}
                    for line in log_file.readlines():

                        # if line contains one of the delimeters you want to extract,
                        if error_delimeter in line:
                            # split line around error delimeter
                            split_line = line.split(f'{error_delimeter}:')
                            # venue,date this error was thrown for
                            origin_log = split_line[0].split('-')
                            date = ''
                            for word in origin_log[2:5]:
                                date += word
                            date = date[0:8]
                            origin_log = f'{origin_log[1]},{date}'

                            # get everything after last occurrence of error delimeter, split by space
                            split_error = split_line[len(split_line) - 1].split()

                            # error is shorter than expected, update script to use fewer words of key to compensate
                            if len(split_error) < 9:
                                print(line)
                                continue
                            error_list = split_error[0:9]

                            # compare the extracted key to list of stored generic error types
                            key = None
                            for x in range(len(error_types)):
                                error_key = error_types[x]
                                split_key = error_key.split()
                                matches = 0
                                matched = False
                                changed = False
                                # if most of the words in key match one of error types, use the error types version
                                for i in range(len(split_key)):
                                    if split_key[i] == error_list[i]:
                                        matches += 1
                                        if matches > 6:
                                            key = error_key
                                            matched = True
                                            break
                                    else:
                                        # replace differing words with generic character, denoting a variable in key
                                        changed = True
                                        split_key[i] = '_'
                                # if error type was made generic and matched with key, update error type with generic
                                if matched and changed:
                                    new_key = ''
                                    for word in split_key:
                                        new_key += f'{word} '
                                    error_types[x] = new_key.rstrip()
                            # if key didn't match an error type, use it and add it to error types
                            if not key:
                                key = ''
                                for word in error_list:
                                    key += f'{word} '
                                error_types.append(key.rstrip())

                            # initialize dictionary layers if not initialized
                            if key not in error_dictionary[error_delimeter]:
                                error_dictionary[error_delimeter][key] = {}
                            if origin_log not in error_dictionary[error_delimeter][key]:
                                error_dictionary[error_delimeter][key][origin_log] = []
                            # add line to lowest dictionary layer
                            error_dictionary[error_delimeter][key][origin_log].append([line, loader, input_file])

                            # if line contains invalid '::' in symbol name, write that to invalid_symbols.csv
                            if '::' in line:
                                if origin_log not in symbol_dictionary:
                                    symbol_dictionary[origin_log] = []

                                split_symbol = line.split('::')
                                first_half = split_symbol[0].split()
                                second_half = split_symbol[1].split()
                                symbol = f'{first_half[len(first_half) - 1]}::{second_half[0]}'
                                # print line with format: SYMBOL,VENUE,DATE
                                if symbol not in symbol_dictionary[origin_log]:
                                    symbol_dictionary[origin_log].append(symbol)
                                    symbol_file.write(f'\n{symbol}{origin_log}')
                # for every line stored in dictionary,
                for key in error_dictionary[error_delimeter]:
                    # store error type
                    error_type = error_dictionary[error_delimeter][key]
                    # convert key to generic key
                    for generic_key in error_types:

                        split_generic = generic_key.split()
                        split_key = key.split()
                        matches = 0
                        for i in range(len(split_generic)):
                            if split_key[i] == split_generic[i]:
                                matches += 1
                                if matches > 6:
                                    key = generic_key
                                    break
                    # print line with format:ERROR_TYPE,VENUE,DATE,COUNT,EXAMPLE_MESSAGE
                    for origin_key in error_type:
                        error_list = error_type[origin_key]
                        output_file.write(f'\n\"{key}...\",{error_list[0][1]},{origin_key},'
                                          f'{len(error_list)},{error_list[0][2]},\"{error_list[0][0].rstrip()}\"')


if __name__ == '__main__':
    main()
