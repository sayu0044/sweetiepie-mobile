// Auto Setup PocketBase Database
// Run this in PocketBase Admin Console

console.log('🚀 Starting PocketBase Database Setup...');

// Function to create collections and fields
async function setupDatabase() {
  try {
    // 1. Update users collection with new fields
    console.log('📝 Updating users collection...');
    
    const usersCollection = $app.dao().findCollectionByNameOrId('users');
    if (!usersCollection) {
      throw new Error('Users collection not found');
    }

    // Add phone field
    const phoneField = new Field();
    phoneField.name = 'phone';
    phoneField.type = 'text';
    phoneField.options = { max: 20 };
    phoneField.required = false;
    usersCollection.schema.addField(phoneField);

    // Add address field
    const addressField = new Field();
    addressField.name = 'address';
    addressField.type = 'text';
    addressField.options = { max: 500 };
    addressField.required = false;
    usersCollection.schema.addField(addressField);

    // Add theme field
    const themeField = new Field();
    themeField.name = 'theme';
    themeField.type = 'select';
    themeField.options = { 
      values: ['light', 'dark', 'system'],
      maxSelect: 1
    };
    themeField.required = false;
    usersCollection.schema.addField(themeField);

    // Add notifications field
    const notificationsField = new Field();
    notificationsField.name = 'notifications';
    notificationsField.type = 'bool';
    notificationsField.required = false;
    usersCollection.schema.addField(notificationsField);

    // Add date_of_birth field
    const dobField = new Field();
    dobField.name = 'date_of_birth';
    dobField.type = 'date';
    dobField.required = false;
    usersCollection.schema.addField(dobField);

    // Add gender field
    const genderField = new Field();
    genderField.name = 'gender';
    genderField.type = 'select';
    genderField.options = { 
      values: ['male', 'female', 'other'],
      maxSelect: 1
    };
    genderField.required = false;
    usersCollection.schema.addField(genderField);

    $app.dao().saveCollection(usersCollection);
    console.log('✅ Users collection updated');

    // 2. Create carts collection
    console.log('📝 Creating carts collection...');
    
    const cartsCollection = new Collection();
    cartsCollection.name = 'carts';
    cartsCollection.type = 'base';
    
    // Add products_id field
    const cartProductsIdField = new Field();
    cartProductsIdField.name = 'products_id';
    cartProductsIdField.type = 'text';
    cartProductsIdField.options = { max: 15 };
    cartProductsIdField.required = true;
    cartsCollection.schema.addField(cartProductsIdField);

    // Add jumlah_barang field
    const cartJumlahField = new Field();
    cartJumlahField.name = 'jumlah_barang';
    cartJumlahField.type = 'number';
    cartJumlahField.options = { min: 1 };
    cartJumlahField.required = true;
    cartsCollection.schema.addField(cartJumlahField);

    // Add users_id field
    const cartUsersIdField = new Field();
    cartUsersIdField.name = 'users_id';
    cartUsersIdField.type = 'text';
    cartUsersIdField.options = { max: 15 };
    cartUsersIdField.required = true;
    cartsCollection.schema.addField(cartUsersIdField);

    // Set API rules
    cartsCollection.listRule = '@request.auth.id != ""';
    cartsCollection.viewRule = '@request.auth.id != "" && users_id = @request.auth.id';
    cartsCollection.createRule = '@request.auth.id != "" && users_id = @request.auth.id';
    cartsCollection.updateRule = '@request.auth.id != "" && users_id = @request.auth.id';
    cartsCollection.deleteRule = '@request.auth.id != "" && users_id = @request.auth.id';

    $app.dao().saveCollection(cartsCollection);
    console.log('✅ Carts collection created');

    // 3. Create likes collection
    console.log('📝 Creating likes collection...');
    
    const likesCollection = new Collection();
    likesCollection.name = 'likes';
    likesCollection.type = 'base';
    
    // Add products_id field
    const likeProductsIdField = new Field();
    likeProductsIdField.name = 'products_id';
    likeProductsIdField.type = 'text';
    likeProductsIdField.options = { max: 15 };
    likeProductsIdField.required = true;
    likesCollection.schema.addField(likeProductsIdField);

    // Add users_id field
    const likeUsersIdField = new Field();
    likeUsersIdField.name = 'users_id';
    likeUsersIdField.type = 'text';
    likeUsersIdField.options = { max: 15 };
    likeUsersIdField.required = true;
    likesCollection.schema.addField(likeUsersIdField);

    // Set API rules
    likesCollection.listRule = '@request.auth.id != ""';
    likesCollection.viewRule = '@request.auth.id != "" && users_id = @request.auth.id';
    likesCollection.createRule = '@request.auth.id != "" && users_id = @request.auth.id';
    likesCollection.updateRule = '@request.auth.id != "" && users_id = @request.auth.id';
    likesCollection.deleteRule = '@request.auth.id != "" && users_id = @request.auth.id';

    $app.dao().saveCollection(likesCollection);
    console.log('✅ Likes collection created');

    console.log('🎉 Database setup completed successfully!');
    
  } catch (error) {
    console.error('❌ Error setting up database:', error);
  }
}

// Run the setup
setupDatabase(); 