/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  console.log('🔧 Applying final API rules fix...');

  try {
    // Update Carts Collection Rules
    console.log('📦 Updating carts collection API rules...');
    const cartsCollection = app.findCollectionByNameOrId("carts");
    
    if (cartsCollection) {
      cartsCollection.createRule = '@request.auth.id != "" && users_id = @request.auth.id';
      cartsCollection.updateRule = '@request.auth.id != "" && users_id = @request.auth.id';
      cartsCollection.deleteRule = '@request.auth.id != "" && users_id = @request.auth.id';
      cartsCollection.listRule = '@request.auth.id != ""';
      cartsCollection.viewRule = '@request.auth.id != "" && users_id = @request.auth.id';
      
      app.save(cartsCollection);
      console.log('✅ Carts collection rules updated successfully');
    } else {
      console.log('⚠️ Carts collection not found');
    }

    // Update Likes Collection Rules
    console.log('❤️ Updating likes collection API rules...');
    const likesCollection = app.findCollectionByNameOrId("likes");
    
    if (likesCollection) {
      likesCollection.createRule = '@request.auth.id != "" && users_id = @request.auth.id';
      likesCollection.updateRule = '@request.auth.id != "" && users_id = @request.auth.id';
      likesCollection.deleteRule = '@request.auth.id != "" && users_id = @request.auth.id';
      likesCollection.listRule = '@request.auth.id != ""';
      likesCollection.viewRule = '@request.auth.id != "" && users_id = @request.auth.id';
      
      app.save(likesCollection);
      console.log('✅ Likes collection rules updated successfully');
    } else {
      console.log('⚠️ Likes collection not found');
    }

    // Update Users Collection Rules
    console.log('👤 Updating users collection API rules...');
    const usersCollection = app.findCollectionByNameOrId("users");
    
    if (usersCollection) {
      usersCollection.updateRule = '@request.auth.id != "" && id = @request.auth.id';
      usersCollection.viewRule = '@request.auth.id != "" && id = @request.auth.id';
      
      app.save(usersCollection);
      console.log('✅ Users collection rules updated successfully');
    } else {
      console.log('⚠️ Users collection not found');
    }

    console.log('🎉 All API rules updated successfully!');

  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  }

}, (app) => {
  console.log('🔄 Rolling back API rules...');

  try {
    // Rollback carts collection
    const cartsCollection = app.findCollectionByNameOrId("carts");
    if (cartsCollection) {
      cartsCollection.createRule = '';
      cartsCollection.updateRule = '';
      cartsCollection.deleteRule = '';
      cartsCollection.listRule = '';
      cartsCollection.viewRule = '';
      app.save(cartsCollection);
    }

    // Rollback likes collection
    const likesCollection = app.findCollectionByNameOrId("likes");
    if (likesCollection) {
      likesCollection.createRule = '';
      likesCollection.updateRule = '';
      likesCollection.deleteRule = '';
      likesCollection.listRule = '';
      likesCollection.viewRule = '';
      app.save(likesCollection);
    }

    console.log('✅ API rules rolled back successfully');

  } catch (error) {
    console.error('❌ Rollback failed:', error);
  }
}); 