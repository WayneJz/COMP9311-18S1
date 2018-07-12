weighted_dict = {0: [(2, 0.2)], 1: [(7, 0.4)], 2: [(0, 0.3), (3, 0.1), (6, 0.2)], 3: [(2, 0.4), (7, 0.3), (9, 0.5)],
                 4: [(9, 0.6)], 5: [(6, 0.3)], 6: [(2, 0.2), (5, 0.3)], 7: [(1, 0.2), (3, 0.2)],
                 8: [(9, 0.2)], 9: [(8, 0.1), (3, 0.1), (4, 0.6)]}


def rec_seek(pointer, weighted_dict, value_dict, occured_list):
    occured_list.append(pointer)
    for x in weighted_dict[pointer]:
        if x[0] not in occured_list:
            value_dict[x[0]] = value_dict[pointer] * x[1]
            rec_seek(x[0], weighted_dict, value_dict, occured_list)


for i in range(0, 10):
    value_dict = dict()
    for j in range(0, 10):
        value_dict[j] = 0
    value_dict[i] = 1
    rec_seek(i, weighted_dict, value_dict, [])
    sum_value = 0
    for k in value_dict.keys():
        sum_value += value_dict[k]
    print(i, sum_value)