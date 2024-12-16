function [random_numbers] = generate_clients(min_quantity, max_quantity, min_value, max_value)

quantity = randi([min_quantity, max_quantity]);

random_numbers = randperm(max_value - min_value + 1, quantity) + min_value - 1;
