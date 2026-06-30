export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      cart_items: {
        Row: {
          cart_id: string
          created_at: string
          id: string
          product_id: string
          qty: number
          updated_at: string
        }
        Insert: {
          cart_id: string
          created_at?: string
          id?: string
          product_id: string
          qty?: number
          updated_at?: string
        }
        Update: {
          cart_id?: string
          created_at?: string
          id?: string
          product_id?: string
          qty?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "cart_items_cart_id_fkey"
            columns: ["cart_id"]
            isOneToOne: false
            referencedRelation: "carts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cart_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      carts: {
        Row: {
          created_at: string
          id: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "carts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      categories: {
        Row: {
          created_at: string
          id: string
          name: string
          slug: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          name: string
          slug?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          name?: string
          slug?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      documents: {
        Row: {
          created_at: string | null
          doc_id: string
          doc_type: string | null
          file_name: string | null
          id: string
          mime_type: string | null
          status: string | null
          storage_path: string | null
          title: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          doc_id: string
          doc_type?: string | null
          file_name?: string | null
          id?: string
          mime_type?: string | null
          status?: string | null
          storage_path?: string | null
          title?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          doc_id?: string
          doc_type?: string | null
          file_name?: string | null
          id?: string
          mime_type?: string | null
          status?: string | null
          storage_path?: string | null
          title?: string | null
          user_id?: string
        }
        Relationships: []
      }
      emergency_contacts: {
        Row: {
          city: string | null
          created_at: string
          id: string
          name: string
          phone: string
          relationship: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          city?: string | null
          created_at?: string
          id?: string
          name: string
          phone: string
          relationship?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          city?: string | null
          created_at?: string
          id?: string
          name?: string
          phone?: string
          relationship?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      enrollments: {
        Row: {
          created_at: string | null
          id: string
          progress: number | null
          status: string | null
          title: string
          user_id: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          progress?: number | null
          status?: string | null
          title: string
          user_id: string
        }
        Update: {
          created_at?: string | null
          id?: string
          progress?: number | null
          status?: string | null
          title?: string
          user_id?: string
        }
        Relationships: []
      }
      favorites: {
        Row: {
          created_at: string
          product_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          product_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          product_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "favorites_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "favorites_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      market_cart_items: {
        Row: {
          created_at: string
          id: string
          product_id: string
          quantity: number
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          product_id: string
          quantity: number
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          product_id?: string
          quantity?: number
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "market_cart_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "market_products"
            referencedColumns: ["id"]
          },
        ]
      }
      market_order_items: {
        Row: {
          created_at: string
          id: string
          line_total_cents: number
          order_id: string
          product_id: string
          quantity: number
          seller_id: string
          title: string
          unit_price_cents: number
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          line_total_cents: number
          order_id: string
          product_id: string
          quantity: number
          seller_id: string
          title: string
          unit_price_cents: number
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          line_total_cents?: number
          order_id?: string
          product_id?: string
          quantity?: number
          seller_id?: string
          title?: string
          unit_price_cents?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "market_order_items_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "market_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "market_order_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "market_products"
            referencedColumns: ["id"]
          },
        ]
      }
      market_orders: {
        Row: {
          buyer_id: string
          created_at: string
          currency: string
          id: string
          shipping_cents: number
          status: string
          subtotal_cents: number
          total_cents: number
          updated_at: string
        }
        Insert: {
          buyer_id: string
          created_at?: string
          currency?: string
          id?: string
          shipping_cents?: number
          status?: string
          subtotal_cents?: number
          total_cents?: number
          updated_at?: string
        }
        Update: {
          buyer_id?: string
          created_at?: string
          currency?: string
          id?: string
          shipping_cents?: number
          status?: string
          subtotal_cents?: number
          total_cents?: number
          updated_at?: string
        }
        Relationships: []
      }
      market_product_media: {
        Row: {
          created_at: string
          id: string
          product_id: string
          sort_order: number
          updated_at: string
          url: string
        }
        Insert: {
          created_at?: string
          id?: string
          product_id: string
          sort_order?: number
          updated_at?: string
          url: string
        }
        Update: {
          created_at?: string
          id?: string
          product_id?: string
          sort_order?: number
          updated_at?: string
          url?: string
        }
        Relationships: [
          {
            foreignKeyName: "market_product_media_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "market_products"
            referencedColumns: ["id"]
          },
        ]
      }
      market_products: {
        Row: {
          created_at: string
          currency: string
          description: string | null
          id: string
          is_active: boolean
          price_cents: number
          seller_id: string
          stock: number
          title: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          currency?: string
          description?: string | null
          id?: string
          is_active?: boolean
          price_cents: number
          seller_id: string
          stock?: number
          title: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          currency?: string
          description?: string | null
          id?: string
          is_active?: boolean
          price_cents?: number
          seller_id?: string
          stock?: number
          title?: string
          updated_at?: string
        }
        Relationships: []
      }
      order_items: {
        Row: {
          created_at: string
          id: string
          order_id: string
          product_id: string
          qty: number
          title_snapshot: string
          unit_price: number
        }
        Insert: {
          created_at?: string
          id?: string
          order_id: string
          product_id: string
          qty?: number
          title_snapshot: string
          unit_price?: number
        }
        Update: {
          created_at?: string
          id?: string
          order_id?: string
          product_id?: string
          qty?: number
          title_snapshot?: string
          unit_price?: number
        }
        Relationships: [
          {
            foreignKeyName: "order_items_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      orders: {
        Row: {
          created_at: string
          currency: string
          id: string
          shipping_address: string | null
          shipping_fee: number
          shipping_name: string | null
          shipping_phone: string | null
          status: Database["public"]["Enums"]["order_status"]
          subtotal: number
          total: number
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          currency?: string
          id?: string
          shipping_address?: string | null
          shipping_fee?: number
          shipping_name?: string | null
          shipping_phone?: string | null
          status?: Database["public"]["Enums"]["order_status"]
          subtotal?: number
          total?: number
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          currency?: string
          id?: string
          shipping_address?: string | null
          shipping_fee?: number
          shipping_name?: string | null
          shipping_phone?: string | null
          status?: Database["public"]["Enums"]["order_status"]
          subtotal?: number
          total?: number
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "orders_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      posts: {
        Row: {
          author_id: string
          created_at: string
          id: string
          media_url: string | null
          product_id: string | null
          text: string | null
          updated_at: string
        }
        Insert: {
          author_id: string
          created_at?: string
          id?: string
          media_url?: string | null
          product_id?: string | null
          text?: string | null
          updated_at?: string
        }
        Update: {
          author_id?: string
          created_at?: string
          id?: string
          media_url?: string | null
          product_id?: string | null
          text?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "posts_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "posts_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      product_images: {
        Row: {
          created_at: string
          id: string
          product_id: string
          sort_order: number
          url: string
        }
        Insert: {
          created_at?: string
          id?: string
          product_id: string
          sort_order?: number
          url: string
        }
        Update: {
          created_at?: string
          id?: string
          product_id?: string
          sort_order?: number
          url?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_images_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      products: {
        Row: {
          category_id: string | null
          compare_at_price: number | null
          created_at: string
          currency: string
          description: string | null
          id: string
          main_image_url: string | null
          price: number
          shop_id: string
          status: Database["public"]["Enums"]["product_status"]
          stock_qty: number
          title: string
          updated_at: string
        }
        Insert: {
          category_id?: string | null
          compare_at_price?: number | null
          created_at?: string
          currency?: string
          description?: string | null
          id?: string
          main_image_url?: string | null
          price?: number
          shop_id: string
          status?: Database["public"]["Enums"]["product_status"]
          stock_qty?: number
          title: string
          updated_at?: string
        }
        Update: {
          category_id?: string | null
          compare_at_price?: number | null
          created_at?: string
          currency?: string
          description?: string | null
          id?: string
          main_image_url?: string | null
          price?: number
          shop_id?: string
          status?: Database["public"]["Enums"]["product_status"]
          stock_qty?: number
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "products_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "products_shop_id_fkey"
            columns: ["shop_id"]
            isOneToOne: false
            referencedRelation: "shops"
            referencedColumns: ["id"]
          },
        ]
      }
      profile_details: {
        Row: {
          address: string | null
          bio: string | null
          birth_place: string | null
          city: string | null
          created_at: string
          father_name: string | null
          full_name: string | null
          marital_status: string | null
          mother_name: string | null
          nationality: string | null
          phone: string | null
          public_bio: boolean
          public_education: boolean
          public_experiences: boolean
          public_languages: boolean
          public_skills: boolean
          thix_account_status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          address?: string | null
          bio?: string | null
          birth_place?: string | null
          city?: string | null
          created_at?: string
          father_name?: string | null
          full_name?: string | null
          marital_status?: string | null
          mother_name?: string | null
          nationality?: string | null
          phone?: string | null
          public_bio?: boolean
          public_education?: boolean
          public_experiences?: boolean
          public_languages?: boolean
          public_skills?: boolean
          thix_account_status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          address?: string | null
          bio?: string | null
          birth_place?: string | null
          city?: string | null
          created_at?: string
          father_name?: string | null
          full_name?: string | null
          marital_status?: string | null
          mother_name?: string | null
          nationality?: string | null
          phone?: string | null
          public_bio?: boolean
          public_education?: boolean
          public_experiences?: boolean
          public_languages?: boolean
          public_skills?: boolean
          thix_account_status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      profile_documents: {
        Row: {
          created_at: string
          doc_type: string
          file_url: string | null
          id: string
          kyc_pack: Json | null
          label: string | null
          status: Database["public"]["Enums"]["document_status"]
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          doc_type: string
          file_url?: string | null
          id?: string
          kyc_pack?: Json | null
          label?: string | null
          status?: Database["public"]["Enums"]["document_status"]
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          doc_type?: string
          file_url?: string | null
          id?: string
          kyc_pack?: Json | null
          label?: string | null
          status?: Database["public"]["Enums"]["document_status"]
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      profile_education: {
        Row: {
          attachments: Json
          created_at: string
          degree: string | null
          description: string | null
          end_year: number | null
          id: string
          institution: string
          level: string | null
          start_year: number | null
          updated_at: string
          user_id: string
        }
        Insert: {
          attachments?: Json
          created_at?: string
          degree?: string | null
          description?: string | null
          end_year?: number | null
          id?: string
          institution: string
          level?: string | null
          start_year?: number | null
          updated_at?: string
          user_id: string
        }
        Update: {
          attachments?: Json
          created_at?: string
          degree?: string | null
          description?: string | null
          end_year?: number | null
          id?: string
          institution?: string
          level?: string | null
          start_year?: number | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      profile_experiences: {
        Row: {
          attachments: Json
          city: string | null
          created_at: string
          end_date: string | null
          id: string
          missions: string | null
          organization: string | null
          sector: string | null
          start_date: string | null
          title: string
          updated_at: string
          user_id: string
        }
        Insert: {
          attachments?: Json
          city?: string | null
          created_at?: string
          end_date?: string | null
          id?: string
          missions?: string | null
          organization?: string | null
          sector?: string | null
          start_date?: string | null
          title: string
          updated_at?: string
          user_id: string
        }
        Update: {
          attachments?: Json
          city?: string | null
          created_at?: string
          end_date?: string | null
          id?: string
          missions?: string | null
          organization?: string | null
          sector?: string | null
          start_date?: string | null
          title?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      profile_languages: {
        Row: {
          created_at: string
          id: string
          level: string | null
          name: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          level?: string | null
          name: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          level?: string | null
          name?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      profile_security_events: {
        Row: {
          created_at: string
          details: Json | null
          event_type: string
          id: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          details?: Json | null
          event_type: string
          id?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          details?: Json | null
          event_type?: string
          id?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      profile_security_settings: {
        Row: {
          biometrics_enabled: boolean
          created_at: string
          two_fa_enabled: boolean
          updated_at: string
          user_id: string
        }
        Insert: {
          biometrics_enabled?: boolean
          created_at?: string
          two_fa_enabled?: boolean
          updated_at?: string
          user_id: string
        }
        Update: {
          biometrics_enabled?: boolean
          created_at?: string
          two_fa_enabled?: boolean
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      profile_skills: {
        Row: {
          created_at: string
          description: string | null
          id: string
          level: Database["public"]["Enums"]["skill_level"]
          name: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          level?: Database["public"]["Enums"]["skill_level"]
          name: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          level?: Database["public"]["Enums"]["skill_level"]
          name?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      profile_transactions: {
        Row: {
          amount_usd: number
          created_at: string
          id: string
          metadata: Json | null
          method: string
          status: Database["public"]["Enums"]["transaction_status"]
          txn_type: Database["public"]["Enums"]["transaction_type"]
          updated_at: string
          user_id: string
        }
        Insert: {
          amount_usd: number
          created_at?: string
          id?: string
          metadata?: Json | null
          method?: string
          status?: Database["public"]["Enums"]["transaction_status"]
          txn_type: Database["public"]["Enums"]["transaction_type"]
          updated_at?: string
          user_id: string
        }
        Update: {
          amount_usd?: number
          created_at?: string
          id?: string
          metadata?: Json | null
          method?: string
          status?: Database["public"]["Enums"]["transaction_status"]
          txn_type?: Database["public"]["Enums"]["transaction_type"]
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      profiles: {
        Row: {
          account_type: string | null
          address: string | null
          biometrics_enabled: boolean | null
          birth_date: string | null
          blood_group: string | null
          competence: string | null
          contact_phone: string | null
          country: string | null
          country_or_origin: string | null
          created_at: string | null
          date_of_birth: string | null
          education: Json | null
          email: string | null
          email_verified: boolean
          emergency_contact_name: string | null
          emergency_contact_phone: string | null
          emergency_contact_relation: string | null
          emergency_contacts: Json | null
          experience: Json | null
          full_name: string | null
          gender: string | null
          has_physical_disability: boolean | null
          height: string | null
          id: string
          id_document_back_doc_id: string | null
          id_document_expiry_date: string | null
          id_document_front_doc_id: string | null
          id_document_issue_date: string | null
          id_document_issue_place: string | null
          id_document_selfie_doc_id: string | null
          id_document_type: string | null
          id_verification_status: string | null
          languages: Json | null
          languages_detailed: Json | null
          marital_status: string | null
          national_id_number: string | null
          nationality: string | null
          occupation: string | null
          origin_province: string | null
          origin_sector: string | null
          origin_territory: string | null
          photo_url: string | null
          physical_disability_description: string | null
          place_of_birth: string | null
          profession: string | null
          registration_status: string | null
          residence_avenue: string | null
          residence_city: string | null
          residence_commune: string | null
          residence_country: string | null
          residence_number: string | null
          residence_province: string | null
          residence_quarter: string | null
          residence_territory: string | null
          skills: Json | null
          thix_chat: string | null
          thix_id: string | null
          thix_score: number | null
          two_fa_enabled: boolean | null
          updated_at: string | null
          user_id: string | null
          visibility: Json | null
          weight: string | null
        }
        Insert: {
          account_type?: string | null
          address?: string | null
          biometrics_enabled?: boolean | null
          birth_date?: string | null
          blood_group?: string | null
          competence?: string | null
          contact_phone?: string | null
          country?: string | null
          country_or_origin?: string | null
          created_at?: string | null
          date_of_birth?: string | null
          education?: Json | null
          email?: string | null
          email_verified?: boolean
          emergency_contact_name?: string | null
          emergency_contact_phone?: string | null
          emergency_contact_relation?: string | null
          emergency_contacts?: Json | null
          experience?: Json | null
          full_name?: string | null
          gender?: string | null
          has_physical_disability?: boolean | null
          height?: string | null
          id: string
          id_document_back_doc_id?: string | null
          id_document_expiry_date?: string | null
          id_document_front_doc_id?: string | null
          id_document_issue_date?: string | null
          id_document_issue_place?: string | null
          id_document_selfie_doc_id?: string | null
          id_document_type?: string | null
          id_verification_status?: string | null
          languages?: Json | null
          languages_detailed?: Json | null
          marital_status?: string | null
          national_id_number?: string | null
          nationality?: string | null
          occupation?: string | null
          origin_province?: string | null
          origin_sector?: string | null
          origin_territory?: string | null
          photo_url?: string | null
          physical_disability_description?: string | null
          place_of_birth?: string | null
          profession?: string | null
          registration_status?: string | null
          residence_avenue?: string | null
          residence_city?: string | null
          residence_commune?: string | null
          residence_country?: string | null
          residence_number?: string | null
          residence_province?: string | null
          residence_quarter?: string | null
          residence_territory?: string | null
          skills?: Json | null
          thix_chat?: string | null
          thix_id?: string | null
          thix_score?: number | null
          two_fa_enabled?: boolean | null
          updated_at?: string | null
          user_id?: string | null
          visibility?: Json | null
          weight?: string | null
        }
        Update: {
          account_type?: string | null
          address?: string | null
          biometrics_enabled?: boolean | null
          birth_date?: string | null
          blood_group?: string | null
          competence?: string | null
          contact_phone?: string | null
          country?: string | null
          country_or_origin?: string | null
          created_at?: string | null
          date_of_birth?: string | null
          education?: Json | null
          email?: string | null
          email_verified?: boolean
          emergency_contact_name?: string | null
          emergency_contact_phone?: string | null
          emergency_contact_relation?: string | null
          emergency_contacts?: Json | null
          experience?: Json | null
          full_name?: string | null
          gender?: string | null
          has_physical_disability?: boolean | null
          height?: string | null
          id?: string
          id_document_back_doc_id?: string | null
          id_document_expiry_date?: string | null
          id_document_front_doc_id?: string | null
          id_document_issue_date?: string | null
          id_document_issue_place?: string | null
          id_document_selfie_doc_id?: string | null
          id_document_type?: string | null
          id_verification_status?: string | null
          languages?: Json | null
          languages_detailed?: Json | null
          marital_status?: string | null
          national_id_number?: string | null
          nationality?: string | null
          occupation?: string | null
          origin_province?: string | null
          origin_sector?: string | null
          origin_territory?: string | null
          photo_url?: string | null
          physical_disability_description?: string | null
          place_of_birth?: string | null
          profession?: string | null
          registration_status?: string | null
          residence_avenue?: string | null
          residence_city?: string | null
          residence_commune?: string | null
          residence_country?: string | null
          residence_number?: string | null
          residence_province?: string | null
          residence_quarter?: string | null
          residence_territory?: string | null
          skills?: Json | null
          thix_chat?: string | null
          thix_id?: string | null
          thix_score?: number | null
          two_fa_enabled?: boolean | null
          updated_at?: string | null
          user_id?: string | null
          visibility?: Json | null
          weight?: string | null
        }
        Relationships: []
      }
      security_events: {
        Row: {
          created_at: string | null
          event_type: string | null
          id: string
          label: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          event_type?: string | null
          id?: string
          label?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          event_type?: string | null
          id?: string
          label?: string | null
          user_id?: string
        }
        Relationships: []
      }
      shops: {
        Row: {
          cover_url: string | null
          created_at: string
          description: string | null
          id: string
          is_active: boolean
          logo_url: string | null
          name: string
          owner_id: string
          slug: string | null
          updated_at: string
        }
        Insert: {
          cover_url?: string | null
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          logo_url?: string | null
          name: string
          owner_id: string
          slug?: string | null
          updated_at?: string
        }
        Update: {
          cover_url?: string | null
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          logo_url?: string | null
          name?: string
          owner_id?: string
          slug?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "shops_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      social_blocks: {
        Row: {
          blocked_id: string
          blocker_id: string
          created_at: string
          id: string
        }
        Insert: {
          blocked_id: string
          blocker_id: string
          created_at?: string
          id?: string
        }
        Update: {
          blocked_id?: string
          blocker_id?: string
          created_at?: string
          id?: string
        }
        Relationships: []
      }
      social_communities: {
        Row: {
          created_at: string
          description: string | null
          id: string
          is_private: boolean
          name: string
          owner_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          is_private?: boolean
          name: string
          owner_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          is_private?: boolean
          name?: string
          owner_id?: string
          updated_at?: string
        }
        Relationships: []
      }
      social_community_members: {
        Row: {
          community_id: string
          created_at: string
          id: string
          role: string
          status: string
          user_id: string
        }
        Insert: {
          community_id: string
          created_at?: string
          id?: string
          role?: string
          status?: string
          user_id: string
        }
        Update: {
          community_id?: string
          created_at?: string
          id?: string
          role?: string
          status?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "social_community_members_community_id_fkey"
            columns: ["community_id"]
            isOneToOne: false
            referencedRelation: "social_communities"
            referencedColumns: ["id"]
          },
        ]
      }
      social_connections: {
        Row: {
          created_at: string
          id: string
          receiver_id: string
          requester_id: string
          status: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          receiver_id: string
          requester_id: string
          status?: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          receiver_id?: string
          requester_id?: string
          status?: string
          updated_at?: string
        }
        Relationships: []
      }
      social_conversation_members: {
        Row: {
          conversation_id: string
          created_at: string
          id: string
          user_id: string
        }
        Insert: {
          conversation_id: string
          created_at?: string
          id?: string
          user_id: string
        }
        Update: {
          conversation_id?: string
          created_at?: string
          id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "social_conversation_members_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "social_conversations"
            referencedColumns: ["id"]
          },
        ]
      }
      social_conversations: {
        Row: {
          created_at: string
          created_by: string
          id: string
          is_group: boolean
          title: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          created_by: string
          id?: string
          is_group?: boolean
          title?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          created_by?: string
          id?: string
          is_group?: boolean
          title?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      social_highlight_items: {
        Row: {
          created_at: string
          highlight_id: string
          id: string
          story_id: string
        }
        Insert: {
          created_at?: string
          highlight_id: string
          id?: string
          story_id: string
        }
        Update: {
          created_at?: string
          highlight_id?: string
          id?: string
          story_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "social_highlight_items_highlight_id_fkey"
            columns: ["highlight_id"]
            isOneToOne: false
            referencedRelation: "social_highlights"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "social_highlight_items_story_id_fkey"
            columns: ["story_id"]
            isOneToOne: false
            referencedRelation: "social_stories"
            referencedColumns: ["id"]
          },
        ]
      }
      social_highlights: {
        Row: {
          created_at: string
          id: string
          owner_id: string
          title: string
        }
        Insert: {
          created_at?: string
          id?: string
          owner_id: string
          title: string
        }
        Update: {
          created_at?: string
          id?: string
          owner_id?: string
          title?: string
        }
        Relationships: []
      }
      social_message_reads: {
        Row: {
          created_at: string
          id: string
          message_id: string
          reader_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          message_id: string
          reader_id: string
        }
        Update: {
          created_at?: string
          id?: string
          message_id?: string
          reader_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "social_message_reads_message_id_fkey"
            columns: ["message_id"]
            isOneToOne: false
            referencedRelation: "social_messages"
            referencedColumns: ["id"]
          },
        ]
      }
      social_messages: {
        Row: {
          attachment_urls: string[]
          body: string
          conversation_id: string
          created_at: string
          id: string
          sender_id: string
          updated_at: string
        }
        Insert: {
          attachment_urls?: string[]
          body: string
          conversation_id: string
          created_at?: string
          id?: string
          sender_id: string
          updated_at?: string
        }
        Update: {
          attachment_urls?: string[]
          body?: string
          conversation_id?: string
          created_at?: string
          id?: string
          sender_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "social_messages_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "social_conversations"
            referencedColumns: ["id"]
          },
        ]
      }
      social_notifications: {
        Row: {
          created_at: string
          description: string
          id: string
          is_unread: boolean
          title: string
          type: string
          user_id: string
        }
        Insert: {
          created_at?: string
          description: string
          id?: string
          is_unread?: boolean
          title: string
          type?: string
          user_id: string
        }
        Update: {
          created_at?: string
          description?: string
          id?: string
          is_unread?: boolean
          title?: string
          type?: string
          user_id?: string
        }
        Relationships: []
      }
      social_post_bookmarks: {
        Row: {
          created_at: string
          id: string
          post_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          post_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          post_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "social_post_bookmarks_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "social_posts"
            referencedColumns: ["id"]
          },
        ]
      }
      social_post_comments: {
        Row: {
          author_avatar_url: string | null
          author_id: string
          author_name: string
          author_role: string | null
          created_at: string
          id: string
          post_id: string
          text: string
          updated_at: string
        }
        Insert: {
          author_avatar_url?: string | null
          author_id: string
          author_name: string
          author_role?: string | null
          created_at?: string
          id?: string
          post_id: string
          text: string
          updated_at?: string
        }
        Update: {
          author_avatar_url?: string | null
          author_id?: string
          author_name?: string
          author_role?: string | null
          created_at?: string
          id?: string
          post_id?: string
          text?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "social_post_comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "social_posts"
            referencedColumns: ["id"]
          },
        ]
      }
      social_post_likes: {
        Row: {
          created_at: string
          id: string
          post_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          post_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          post_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "social_post_likes_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "social_posts"
            referencedColumns: ["id"]
          },
        ]
      }
      social_posts: {
        Row: {
          author_avatar_url: string | null
          author_id: string
          author_is_verified: boolean
          author_mutual_connections: number
          author_name: string
          author_role: string | null
          challenge: Json | null
          comment_count: number
          community_name: string | null
          content: string
          created_at: string
          hashtags: string[]
          id: string
          is_pinned: boolean
          kind: string
          like_count: number
          media_urls: string[]
          mentions: string[]
          poll: Json | null
          quote: string | null
          repost_author_name: string | null
          repost_of_post_id: string | null
          share_count: number
          updated_at: string
          view_count: number
          visibility: string
        }
        Insert: {
          author_avatar_url?: string | null
          author_id: string
          author_is_verified?: boolean
          author_mutual_connections?: number
          author_name: string
          author_role?: string | null
          challenge?: Json | null
          comment_count?: number
          community_name?: string | null
          content: string
          created_at?: string
          hashtags?: string[]
          id?: string
          is_pinned?: boolean
          kind?: string
          like_count?: number
          media_urls?: string[]
          mentions?: string[]
          poll?: Json | null
          quote?: string | null
          repost_author_name?: string | null
          repost_of_post_id?: string | null
          share_count?: number
          updated_at?: string
          view_count?: number
          visibility?: string
        }
        Update: {
          author_avatar_url?: string | null
          author_id?: string
          author_is_verified?: boolean
          author_mutual_connections?: number
          author_name?: string
          author_role?: string | null
          challenge?: Json | null
          comment_count?: number
          community_name?: string | null
          content?: string
          created_at?: string
          hashtags?: string[]
          id?: string
          is_pinned?: boolean
          kind?: string
          like_count?: number
          media_urls?: string[]
          mentions?: string[]
          poll?: Json | null
          quote?: string | null
          repost_author_name?: string | null
          repost_of_post_id?: string | null
          share_count?: number
          updated_at?: string
          view_count?: number
          visibility?: string
        }
        Relationships: [
          {
            foreignKeyName: "social_posts_repost_of_post_id_fkey"
            columns: ["repost_of_post_id"]
            isOneToOne: false
            referencedRelation: "social_posts"
            referencedColumns: ["id"]
          },
        ]
      }
      social_profile_visits: {
        Row: {
          created_at: string
          id: string
          profile_user_id: string
          visitor_user_id: string | null
        }
        Insert: {
          created_at?: string
          id?: string
          profile_user_id: string
          visitor_user_id?: string | null
        }
        Update: {
          created_at?: string
          id?: string
          profile_user_id?: string
          visitor_user_id?: string | null
        }
        Relationships: []
      }
      social_profiles: {
        Row: {
          avatar_url: string | null
          created_at: string
          display_name: string
          headline: string
          updated_at: string
          user_id: string
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string
          display_name: string
          headline?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          avatar_url?: string | null
          created_at?: string
          display_name?: string
          headline?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      social_reports: {
        Row: {
          created_at: string
          id: string
          post_id: string | null
          reason: string
          reported_user_id: string | null
          reporter_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          post_id?: string | null
          reason: string
          reported_user_id?: string | null
          reporter_id: string
        }
        Update: {
          created_at?: string
          id?: string
          post_id?: string | null
          reason?: string
          reported_user_id?: string | null
          reporter_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "social_reports_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "social_posts"
            referencedColumns: ["id"]
          },
        ]
      }
      social_stories: {
        Row: {
          author_id: string
          author_name: string
          created_at: string
          expires_at: string
          id: string
          is_video: boolean
          media_url: string | null
          view_count: number
        }
        Insert: {
          author_id: string
          author_name: string
          created_at?: string
          expires_at?: string
          id?: string
          is_video?: boolean
          media_url?: string | null
          view_count?: number
        }
        Update: {
          author_id?: string
          author_name?: string
          created_at?: string
          expires_at?: string
          id?: string
          is_video?: boolean
          media_url?: string | null
          view_count?: number
        }
        Relationships: []
      }
      social_story_views: {
        Row: {
          created_at: string
          id: string
          story_id: string
          viewer_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          story_id: string
          viewer_id: string
        }
        Update: {
          created_at?: string
          id?: string
          story_id?: string
          viewer_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "social_story_views_story_id_fkey"
            columns: ["story_id"]
            isOneToOne: false
            referencedRelation: "social_stories"
            referencedColumns: ["id"]
          },
        ]
      }
      thix_event_bookings: {
        Row: {
          attendee_email: string | null
          attendee_name: string | null
          cover_image_url: string
          created_at: string
          currency: string
          event_date: string
          event_id: string
          event_title: string
          event_venue: string
          id: string
          qr_payload: string
          quantity: number
          status: string
          ticket_code: string
          total_price_cents: number
          updated_at: string
          user_id: string
        }
        Insert: {
          attendee_email?: string | null
          attendee_name?: string | null
          cover_image_url: string
          created_at?: string
          currency?: string
          event_date: string
          event_id: string
          event_title: string
          event_venue: string
          id?: string
          qr_payload: string
          quantity: number
          status?: string
          ticket_code: string
          total_price_cents: number
          updated_at?: string
          user_id: string
        }
        Update: {
          attendee_email?: string | null
          attendee_name?: string | null
          cover_image_url?: string
          created_at?: string
          currency?: string
          event_date?: string
          event_id?: string
          event_title?: string
          event_venue?: string
          id?: string
          qr_payload?: string
          quantity?: number
          status?: string
          ticket_code?: string
          total_price_cents?: number
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "thix_event_bookings_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "thix_events"
            referencedColumns: ["id"]
          },
        ]
      }
      thix_event_favorites: {
        Row: {
          created_at: string
          event_id: string
          id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          event_id: string
          id?: string
          user_id: string
        }
        Update: {
          created_at?: string
          event_id?: string
          id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "thix_event_favorites_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "thix_events"
            referencedColumns: ["id"]
          },
        ]
      }
      thix_events: {
        Row: {
          attendees_count: number
          badge_label: string | null
          category: string
          city: string
          cover_image_url: string
          created_at: string
          currency: string
          description: string
          ends_at: string | null
          favorites_count: number
          gallery_urls: string[]
          id: string
          is_featured: boolean
          is_published: boolean
          is_recommended: boolean
          is_trending: boolean
          organizer_id: string | null
          organizer_name: string
          organizer_verified: boolean
          price_cents: number
          rating: number
          review_count: number
          seats_remaining: number
          seats_total: number
          starts_at: string
          summary: string
          tags: string[]
          title: string
          updated_at: string
          venue: string
        }
        Insert: {
          attendees_count?: number
          badge_label?: string | null
          category: string
          city: string
          cover_image_url: string
          created_at?: string
          currency?: string
          description?: string
          ends_at?: string | null
          favorites_count?: number
          gallery_urls?: string[]
          id?: string
          is_featured?: boolean
          is_published?: boolean
          is_recommended?: boolean
          is_trending?: boolean
          organizer_id?: string | null
          organizer_name?: string
          organizer_verified?: boolean
          price_cents?: number
          rating?: number
          review_count?: number
          seats_remaining?: number
          seats_total?: number
          starts_at: string
          summary?: string
          tags?: string[]
          title: string
          updated_at?: string
          venue: string
        }
        Update: {
          attendees_count?: number
          badge_label?: string | null
          category?: string
          city?: string
          cover_image_url?: string
          created_at?: string
          currency?: string
          description?: string
          ends_at?: string | null
          favorites_count?: number
          gallery_urls?: string[]
          id?: string
          is_featured?: boolean
          is_published?: boolean
          is_recommended?: boolean
          is_trending?: boolean
          organizer_id?: string | null
          organizer_name?: string
          organizer_verified?: boolean
          price_cents?: number
          rating?: number
          review_count?: number
          seats_remaining?: number
          seats_total?: number
          starts_at?: string
          summary?: string
          tags?: string[]
          title?: string
          updated_at?: string
          venue?: string
        }
        Relationships: []
      }
      transactions: {
        Row: {
          amount: number | null
          created_at: string | null
          currency: string | null
          id: string
          method: string | null
          status: string | null
          title: string | null
          user_id: string
        }
        Insert: {
          amount?: number | null
          created_at?: string | null
          currency?: string | null
          id?: string
          method?: string | null
          status?: string | null
          title?: string | null
          user_id: string
        }
        Update: {
          amount?: number | null
          created_at?: string | null
          currency?: string | null
          id?: string
          method?: string | null
          status?: string | null
          title?: string | null
          user_id?: string
        }
        Relationships: []
      }
      users: {
        Row: {
          auth_user_id: string | null
          birth_date: string | null
          country: string | null
          created_at: string
          email: string
          id: string
          name: string
          updated_at: string
        }
        Insert: {
          auth_user_id?: string | null
          birth_date?: string | null
          country?: string | null
          created_at?: string
          email: string
          id: string
          name: string
          updated_at?: string
        }
        Update: {
          auth_user_id?: string | null
          birth_date?: string | null
          country?: string | null
          created_at?: string
          email?: string
          id?: string
          name?: string
          updated_at?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      _thix_random_block: { Args: { len: number }; Returns: string }
      generate_thix_id: { Args: never; Returns: string }
      reserve_thix_event: {
        Args: {
          p_attendee_email?: string
          p_attendee_name?: string
          p_event_id: string
          p_quantity?: number
        }
        Returns: {
          attendee_email: string | null
          attendee_name: string | null
          cover_image_url: string
          created_at: string
          currency: string
          event_date: string
          event_id: string
          event_title: string
          event_venue: string
          id: string
          qr_payload: string
          quantity: number
          status: string
          ticket_code: string
          total_price_cents: number
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "thix_event_bookings"
          isOneToOne: true
          isSetofReturn: false
        }
      }
    }
    Enums: {
      document_status: "pending" | "verified" | "rejected"
      order_status:
        | "pending"
        | "confirmed"
        | "shipped"
        | "delivered"
        | "cancelled"
      product_status: "draft" | "active" | "out_of_stock" | "archived"
      skill_level: "beginner" | "intermediate" | "advanced" | "expert"
      transaction_status: "pending" | "success" | "failed" | "refunded"
      transaction_type: "activation" | "document_upload"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      document_status: ["pending", "verified", "rejected"],
      order_status: [
        "pending",
        "confirmed",
        "shipped",
        "delivered",
        "cancelled",
      ],
      product_status: ["draft", "active", "out_of_stock", "archived"],
      skill_level: ["beginner", "intermediate", "advanced", "expert"],
      transaction_status: ["pending", "success", "failed", "refunded"],
      transaction_type: ["activation", "document_upload"],
    },
  },
} as const
