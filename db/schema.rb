# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_01_22_102551) do

  create_table "blogs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "diffs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "page_id"
    t.text "coordinates"
    t.string "diff_image_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "src_screenshot_id"
    t.bigint "dest_screenshot_id"
    t.index ["dest_screenshot_id"], name: "fk_rails_fa9d39b035"
    t.index ["page_id"], name: "index_diffs_on_page_id"
    t.index ["src_screenshot_id"], name: "fk_rails_7d66abc544"
  end

  create_table "pages", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "blog_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["blog_id"], name: "index_pages_on_blog_id"
  end

  create_table "screenshots", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "blog_id"
    t.bigint "snapshot_id"
    t.string "sid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "page_id"
    t.integer "resp_code"
    t.index ["blog_id"], name: "index_screenshots_on_blog_id"
    t.index ["page_id"], name: "index_screenshots_on_page_id"
    t.index ["snapshot_id"], name: "index_screenshots_on_snapshot_id"
  end

  create_table "snapshots", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "blog_id"
    t.index ["blog_id"], name: "index_snapshots_on_blog_id"
  end

  create_table "unionchanges", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "page_id"
    t.text "coordinates"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["page_id"], name: "index_unionchanges_on_page_id"
  end

  add_foreign_key "diffs", "screenshots", column: "dest_screenshot_id"
  add_foreign_key "diffs", "screenshots", column: "src_screenshot_id"
  add_foreign_key "pages", "blogs"
  add_foreign_key "screenshots", "blogs"
  add_foreign_key "screenshots", "pages"
  add_foreign_key "screenshots", "snapshots"
  add_foreign_key "snapshots", "blogs"
  add_foreign_key "unionchanges", "pages"
end
