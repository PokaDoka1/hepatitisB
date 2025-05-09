groceries = {
  'safeway': {'eggs': 1, 'coconut milk': 3}, 
  'costco': {'croissant': 12}
}

# safeway:flour,1 + eggs,2 
inner = groceries['safeway']
inner['flour'] = 1
inner['eggs'] += 2

# costco:milk,3
inner = groceries['costco']
inner['milk'] = 3

# target:sugar cookies,1
groceries['target'] = {}

inner = groceries['target']
inner['sugar cookies'] = 1

def add_item(groceries, store, item, num):
    if store not in groceries:
        groceries[store] = {}
        
    inner = groceries[store]
    if item in groceries:
            inner[item] += num
    else:
        inner = groceries[store]
    
    
    """ REDUDANT CODE:
    
    if store in groceries:
        inner = groceries[store]
        
        if item in groceries:
            inner[item] += num
        else:
            inner = groceries[store]
            
    else:
        groceries[store]={}
        inner = groceries[store]
        inner[item] = num 
    """
        
add_item(groceries, 'walmart', 'mango', 3)
print(groceries)
