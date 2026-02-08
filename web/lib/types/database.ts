export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export interface Database {
  house: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          email: string;
          display_name: string | null;
          avatar_url: string | null;
          color: string | null;
          created_at: string | null;
          updated_at: string | null;
        };
        Insert: {
          id: string;
          email: string;
          display_name?: string | null;
          avatar_url?: string | null;
          color?: string | null;
        };
        Update: {
          display_name?: string | null;
          avatar_url?: string | null;
          color?: string | null;
        };
      };
      ledgers: {
        Row: {
          id: string;
          name: string;
          description: string | null;
          currency: string;
          owner_id: string;
          is_shared: boolean;
          created_at: string | null;
          updated_at: string | null;
        };
        Insert: {
          id?: string;
          name: string;
          description?: string | null;
          currency?: string;
          owner_id: string;
          is_shared?: boolean;
        };
        Update: {
          name?: string;
          description?: string | null;
          currency?: string;
          is_shared?: boolean;
        };
      };
      ledger_members: {
        Row: {
          id: string;
          ledger_id: string;
          user_id: string;
          role: 'owner' | 'admin' | 'member';
          created_at: string | null;
        };
        Insert: {
          id?: string;
          ledger_id: string;
          user_id: string;
          role?: 'owner' | 'admin' | 'member';
        };
        Update: {
          role?: 'owner' | 'admin' | 'member';
        };
      };
      categories: {
        Row: {
          id: string;
          ledger_id: string;
          name: string;
          type: 'income' | 'expense' | 'asset';
          icon: string | null;
          color: string | null;
          sort_order: number;
          is_default: boolean;
          created_at: string | null;
        };
        Insert: {
          id?: string;
          ledger_id: string;
          name: string;
          type: 'income' | 'expense' | 'asset';
          icon?: string | null;
          color?: string | null;
          sort_order?: number;
          is_default?: boolean;
        };
        Update: {
          name?: string;
          type?: 'income' | 'expense' | 'asset';
          icon?: string | null;
          color?: string | null;
          sort_order?: number;
        };
      };
      transactions: {
        Row: {
          id: string;
          ledger_id: string;
          category_id: string | null;
          payment_method_id: string | null;
          user_id: string;
          type: 'income' | 'expense' | 'asset';
          amount: number;
          title: string;
          memo: string | null;
          date: string;
          is_asset: boolean;
          maturity_date: string | null;
          created_at: string | null;
          updated_at: string | null;
        };
        Insert: {
          id?: string;
          ledger_id: string;
          category_id?: string | null;
          payment_method_id?: string | null;
          user_id: string;
          type: 'income' | 'expense' | 'asset';
          amount: number;
          title: string;
          memo?: string | null;
          date: string;
          is_asset?: boolean;
          maturity_date?: string | null;
        };
        Update: {
          category_id?: string | null;
          payment_method_id?: string | null;
          type?: 'income' | 'expense' | 'asset';
          amount?: number;
          title?: string;
          memo?: string | null;
          date?: string;
          is_asset?: boolean;
          maturity_date?: string | null;
        };
      };
      payment_methods: {
        Row: {
          id: string;
          ledger_id: string;
          name: string;
          type: string;
          icon: string | null;
          color: string | null;
          auto_save_mode: 'manual' | 'suggest' | 'auto';
          default_category_id: string | null;
          can_auto_save: boolean;
          owner_user_id: string | null;
          created_at: string | null;
        };
        Insert: {
          id?: string;
          ledger_id: string;
          name: string;
          type: string;
          icon?: string | null;
          color?: string | null;
          auto_save_mode?: 'manual' | 'suggest' | 'auto';
          default_category_id?: string | null;
          can_auto_save?: boolean;
          owner_user_id?: string | null;
        };
        Update: {
          name?: string;
          type?: string;
          icon?: string | null;
          color?: string | null;
          auto_save_mode?: 'manual' | 'suggest' | 'auto';
          default_category_id?: string | null;
          can_auto_save?: boolean;
        };
      };
      budgets: {
        Row: {
          id: string;
          ledger_id: string;
          category_id: string;
          amount: number;
          year: number;
          month: number;
          created_at: string | null;
          updated_at: string | null;
        };
        Insert: {
          id?: string;
          ledger_id: string;
          category_id: string;
          amount: number;
          year: number;
          month: number;
        };
        Update: {
          amount?: number;
          year?: number;
          month?: number;
        };
      };
      ledger_invites: {
        Row: {
          id: string;
          ledger_id: string;
          inviter_id: string;
          invitee_email: string;
          role: 'admin' | 'member';
          status: 'pending' | 'accepted' | 'rejected';
          created_at: string | null;
          expires_at: string | null;
        };
        Insert: {
          id?: string;
          ledger_id: string;
          inviter_id: string;
          invitee_email: string;
          role?: 'admin' | 'member';
          status?: 'pending' | 'accepted' | 'rejected';
          expires_at?: string | null;
        };
        Update: {
          status?: 'pending' | 'accepted' | 'rejected';
        };
      };
      fcm_tokens: {
        Row: {
          id: string;
          user_id: string;
          token: string;
          device_info: Json | null;
          created_at: string | null;
        };
        Insert: {
          id?: string;
          user_id: string;
          token: string;
          device_info?: Json | null;
        };
        Update: {
          token?: string;
          device_info?: Json | null;
        };
      };
      notification_settings: {
        Row: {
          id: string;
          user_id: string;
          transaction_alert: boolean;
          budget_alert: boolean;
          share_alert: boolean;
          daily_summary: boolean;
          created_at: string | null;
          updated_at: string | null;
        };
        Insert: {
          id?: string;
          user_id: string;
          transaction_alert?: boolean;
          budget_alert?: boolean;
          share_alert?: boolean;
          daily_summary?: boolean;
        };
        Update: {
          transaction_alert?: boolean;
          budget_alert?: boolean;
          share_alert?: boolean;
          daily_summary?: boolean;
        };
      };
    };
    Functions: {
      check_user_exists_by_email: {
        Args: { target_email: string };
        Returns: { id: string; email: string; display_name: string }[];
      };
      user_can_access_ledger: {
        Args: { p_ledger_id: string };
        Returns: boolean;
      };
      increment_sms_format_match_count: {
        Args: { format_id: string };
        Returns: void;
      };
    };
  };
}

// 편의 타입 별칭
export type Profile = Database['house']['Tables']['profiles']['Row'];
export type Ledger = Database['house']['Tables']['ledgers']['Row'];
export type LedgerMember = Database['house']['Tables']['ledger_members']['Row'];
export type Category = Database['house']['Tables']['categories']['Row'];
export type Transaction = Database['house']['Tables']['transactions']['Row'];
export type PaymentMethod = Database['house']['Tables']['payment_methods']['Row'];
export type Budget = Database['house']['Tables']['budgets']['Row'];
export type LedgerInvite = Database['house']['Tables']['ledger_invites']['Row'];
export type NotificationSettings = Database['house']['Tables']['notification_settings']['Row'];

// Insert 타입 별칭
export type TransactionInsert = Database['house']['Tables']['transactions']['Insert'];
export type CategoryInsert = Database['house']['Tables']['categories']['Insert'];
export type PaymentMethodInsert = Database['house']['Tables']['payment_methods']['Insert'];
export type BudgetInsert = Database['house']['Tables']['budgets']['Insert'];
