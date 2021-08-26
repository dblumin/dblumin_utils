import datetime
import boto3
from os import path, remove
import gzip
import shutil
import subprocess
import click
"""import pandas
import numpy"""


VENUES = ['CBT', 'CME', 'CMX', 'GEM', 'IMM', 'IOM', 'NYM']


def string_to_time(line):
    line = line.rstrip()
    year = line[0:4]
    month = line[5:7]
    day = line[8:10]
    hour = line[11:13]
    minute = line[14:16]
    second = line[17:19]
    
    return datetime.datetime(year=int(year), month=int(month), day=int(day), hour=int(hour), minute=int(minute), second=int(second))


def process_with_filestream(directory, filename, first_tick, last_tick, output_file):
    with open(f'{directory}/{filename}', 'r') as input_file:
        i = 0
        for line in input_file.readlines():
            i += 1
            if i % 100000 == 0:
                print(f'processed {i} rows')
            # clunky, but faster than using split(',')
            first_colon = line.find(':')
            if first_colon > -1:
                first_ts = line[first_colon - 13 : first_colon + 6].rstrip()
                if len(first_ts) > 18:
                    first_time = string_to_time(first_ts)
                    if first_time and first_time < first_tick[1]:
                        first_tick[0] = line
                        first_tick[1] = first_time
                    remainder = line[first_colon + 12: len(line)]
                    second_colon = remainder.find(':')
                    if second_colon > -1:
                        second_ts = remainder[second_colon - 13 : second_colon + 6].rstrip()
                        if len(second_ts) > 18:
                            second_time = string_to_time(second_ts)
                            if second_time and second_time > last_tick[1]:
                                last_tick[0] = line
                                last_tick[1] = second_time

    output_file.write(f'{filename},{first_tick[0]},{last_tick[0]}\n')


"""
# significantly slower; overhead of pandas.read_csv() isn't worth it for data processing that has to go line-by-line
def process_with_numpy_array(directory, filename, first_tick, last_tick, output_file):
    df = pandas.read_csv(f'{directory}/{filename}')
    i = 0
    for row in df.values:
        i += 1
        if i % 100000 == 0:
            print(f'processed {i} rows')

        first_ts = str(row[2]).rstrip()

        if len(first_ts) > 18:
            first_time = string_to_time(first_ts)
            if first_time and first_time < first_tick[1]:
                first_tick[0] = row
                first_tick[1] = first_time
            second_ts = str(row[3]).rstrip()
            if len(second_ts) > 18:
                second_time = string_to_time(second_ts)
                if second_time and second_time > last_tick[1]:
                    last_tick[0] = row
                    last_tick[1] = second_time

    output_file.write(f'{filename},{first_tick[0]},{last_tick[0]}\n')
"""


def extract_timestamps(directory, start, end_date):
    with open(f'{directory}/timestamp_summary_consolidated.csv', 'w+') as output_file:
        output_file.seek(0)
        output_file.truncate(0)
        start_split = start.split('-')
        for venue in VENUES:
            start_date = datetime.date(year=int(start_split[0]), month=int(start_split[1]), day=int(start_split[2]))
            while start_date <= end_date:
                formatted_date = start_date.strftime('%Y-%m-%d')
                filename = f'{venue}-{formatted_date}-MARKETPRICE-Report-1-of-1.csv'

                first_tick = ['N/A', datetime.datetime(year=9999, month=1, day=1, hour=0, minute=0, second=0)]
                last_tick = ['N/A', datetime.datetime(year=1, month=1, day=1, hour=0, minute=0, second=0)]
                process_with_filestream(directory, filename, first_tick, last_tick, output_file)

                start_date += datetime.timedelta(days=1)


def s3_download(bucket, key, destination):
    client = boto3.client('s3', region_name='us-east-2')

    if path.isfile(destination):
        print("file exists")
    else:
        client.download_file(bucket, key, destination)


@click.command()
@click.option('--start', default='2020-01-01', show_default=True, help='''Start date.''')
@click.option('--end', default='2020-12-31', show_default=True, help='''End date.''')
@click.option('--directory', default='2020', show_default=True, help='''Directory to download to.''')
@click.option('--download_only', is_flag=True, show_default=True, help='''If set, only download files.''')
def main(start, end, directory, download_only):
    start_timer = datetime.datetime.now()
    start_split = start.split('-')
    end_split = end.split('-')
    end_date = datetime.date(year=int(end_split[0]), month=int(end_split[1]), day=int(end_split[2]))

    # for each venue
    for venue in VENUES:

        start_date = datetime.date(year=int(start_split[0]), month=int(start_split[1]), day=int(start_split[2]))
        # for each date in range
        while start_date <= end_date:
            # download file
            formatted_date = start_date.strftime('%Y-%m-%d')
            bucket = 'onetick-uat-ro-mfba384xucaypxeczb9ch5hqykprcuse2a-s3alias'
            filename = f'{venue}-{formatted_date}-MARKETPRICE-Report-1-of-1.csv'
            destination = f'/mnt/onetick/efs/data2/extracted/{directory}/{filename}'
            filename += '.gz'
            key = f'{venue}/{formatted_date}/{filename}'
            zipped = f'{destination}.gz'
            print(f'downloading {filename}...')
            s3_download(bucket, key, zipped)
            # unzip file
            print(f'unzipping {zipped}...')
            with gzip.open(zipped, 'rb') as file_zipped:
                with open(destination, 'wb') as file_unzipped:
                    shutil.copyfileobj(file_zipped, file_unzipped)
            remove(zipped)
            start_date += datetime.timedelta(days=1)

    # all files downloaded: extract timestamps:
    if not download_only:
        extract_timestamps(directory, start, end_date)
    
    print(f'Ran in {datetime.datetime.now() - start_timer}')


if __name__ == '__main__':
    main()
