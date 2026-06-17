import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import LabelEncoder
import pickle

# Training data — past sales by day and product
data = pd.DataFrame({
    'day_of_week': [0,1,2,3,4,5,6, 0,1,2,3,4,5,6, 0,1,2,3,4,5,6, 0,1,2,3,4,5,6],
    'product': [
        'milk','milk','milk','milk','milk','milk','milk',
        'bread','bread','bread','bread','bread','bread','bread',
        'tomatoes','tomatoes','tomatoes','tomatoes','tomatoes','tomatoes','tomatoes',
        'eggs','eggs','eggs','eggs','eggs','eggs','eggs'
    ],
    'quantity_sold': [
        10,8,12,9,18,22,15,
        5,4,6,5,10,12,8,
        14,12,15,13,20,25,18,
        8,7,9,8,14,16,12
    ],
})

le = LabelEncoder()
data['product_enc'] = le.fit_transform(data['product'])

X = data[['day_of_week', 'product_enc']]
y = data['quantity_sold']

model = LinearRegression().fit(X, y)

with open('model.pkl', 'wb') as f:
    pickle.dump({'model': model, 'encoder': le}, f)

debugPrint("Success: Model trained and saved as model.pkl!")
debugPrint(f"   Products learned: {list(le.classes_)}")
