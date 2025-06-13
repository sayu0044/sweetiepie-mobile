/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  console.log('🔧 Fixing orders and likes collections...');

  try {
    // Fix Orders Collection - make payment_method_id optional
    console.log('📦 Updating orders collection...');
    const ordersCollection = app.findCollectionByNameOrId("orders");
    
    if (ordersCollection) {
      // Find payment_method_id field and make it optional
      const paymentMethodField = ordersCollection.fields.find(field => field.name === 'payment_method_id');
      if (paymentMethodField) {
        paymentMethodField.required = false;
        console.log('✅ Made payment_method_id optional in orders collection');
      }
      
      app.save(ordersCollection);
      console.log('✅ Orders collection updated successfully');
    } else {
      console.log('⚠️ Orders collection not found');
    }

    // Fix Likes Collection - ensure proper field configuration
    console.log('❤️ Updating likes collection...');
    const likesCollection = app.findCollectionByNameOrId("likes");
    
    if (likesCollection) {
      // Make sure products_id and users_id are properly configured
      const productsIdField = likesCollection.fields.find(field => field.name === 'products_id');
      const usersIdField = likesCollection.fields.find(field => field.name === 'users_id');
      
      if (productsIdField) {
        productsIdField.required = true;
        console.log('✅ Made products_id required in likes collection');
      }
      
      if (usersIdField) {
        usersIdField.required = true;
        console.log('✅ Made users_id required in likes collection');
      }
      
      app.save(likesCollection);
      console.log('✅ Likes collection updated successfully');
    } else {
      console.log('⚠️ Likes collection not found');
    }

    console.log('🎉 Orders and likes collections fixed successfully!');

  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  }

}, (app) => {
  console.log('🔄 Rolling back orders and likes fixes...');

  try {
    // Rollback orders collection
    const ordersCollection = app.findCollectionByNameOrId("orders");
    if (ordersCollection) {
      const paymentMethodField = ordersCollection.fields.find(field => field.name === 'payment_method_id');
      if (paymentMethodField) {
        paymentMethodField.required = true;
      }
      app.save(ordersCollection);
    }

    console.log('✅ Orders and likes rollback completed');

  } catch (error) {
    console.error('❌ Rollback failed:', error);
  }
}); 