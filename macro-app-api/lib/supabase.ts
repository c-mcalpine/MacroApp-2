import { createClient } from '@supabase/supabase-js';

if (!process.env.SUPABASE_URL || !process.env.SUPABASE_ANON_KEY) {
  throw new Error('Missing Supabase credentials');
}

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// Helper functions for common Supabase operations
export async function getUserByPhone(phone: string) {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('phone_number', phone)
      .single();

    if (error) {
      console.error('Error fetching user:', error);
      return null;
    }

    return data;
  } catch (error) {
    console.error('Error in getUserByPhone:', error);
    return null;
  }
}

export async function createUser(phone: string, username: string) {
  try {
    const { data, error } = await supabase
      .from('users')
      .insert([
        { 
          phone_number: phone, 
          username: username,
          created_at: new Date().toISOString()
        }
      ])
      .select()
      .single();

    if (error) {
      console.error('Error creating user:', error);
      return null;
    }

    return data;
  } catch (error) {
    console.error('Error in createUser:', error);
    return null;
  }
}

export async function updateUsername(phone: string, username: string) {
  try {
    const { data, error } = await supabase
      .from('users')
      .update({ username: username })
      .eq('phone_number', phone)
      .select()
      .single();

    if (error) {
      console.error('Error updating username:', error);
      return { success: false, error: error.message };
    }

    return { success: true, data };
  } catch (error) {
    console.error('Error in updateUsername:', error);
    return { success: false, error: 'Failed to update username' };
  }
}

export async function getRecipeById(id: string) {
  try {
    const { data, error } = await supabase
      .from('recipes')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      console.error('Error fetching recipe:', error);
      return null;
    }

    return data;
  } catch (error) {
    console.error('Error in getRecipeById:', error);
    return null;
  }
}

export async function getAllRecipes() {
  try {
    const { data, error } = await supabase
      .from('recipes')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching recipes:', error);
      return [];
    }

    return data;
  } catch (error) {
    console.error('Error in getAllRecipes:', error);
    return [];
  }
}

export async function searchRecipes(query: string, filters: Record<string, any> = {}) {
  try {
    let queryBuilder = supabase
      .from('recipes')
      .select('*')
      .textSearch('name', query);

    // Apply filters
    Object.entries(filters).forEach(([key, value]) => {
      if (value !== undefined) {
        queryBuilder = queryBuilder.gte(key, value);
      }
    });

    const { data, error } = await queryBuilder;

    if (error) {
      console.error('Error searching recipes:', error);
      return [];
    }

    return data;
  } catch (error) {
    console.error('Error in searchRecipes:', error);
    return [];
  }
} 