-- --------------------------------
-- Start of India GST Tax Changes
-- --------------------------------

INSERT INTO `ospos_app_config` (`key`, `value`) VALUES
('include_hsn', '0'),
('invoice_type', 'invoice'),
('default_tax_jurisdiction', ''),
('tax_id', '');

UPDATE `ospos_app_config`
  SET `key` = 'use_destination_based_tax'
  WHERE `key` = 'customer_sales_tax_support';

UPDATE `ospos_app_config`
  SET `key` = 'default_tax_code'
  WHERE `key` = 'default_origin_tax_code';


RENAME TABLE `ospos_tax_codes` TO `ospos_tax_codes_backup`;

CREATE TABLE IF NOT EXISTS `ospos_tax_codes` (
  `tax_code_id` int(11) NOT NULL AUTO_INCREMENT,
  `tax_code` varchar(32) NOT NULL,
  `tax_code_name` varchar(255) NOT NULL DEFAULT '',
  `city` varchar(255) NOT NULL DEFAULT '',
  `state` varchar(255) NOT NULL DEFAULT '',
  `deleted` int(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`tax_code_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `ospos_tax_codes` (`tax_code`,`tax_code_name`,`city`,`state`)
SELECT `tax_code`,`tax_code_name`,`city`,`state`
FROM `ospos_tax_codes_backup`;

DROP TABLE `ospos_tax_codes_backup`;

ALTER TABLE `ospos_customers`
  ADD COLUMN `tax_id` varchar(32) NOT NULL DEFAULT '' AFTER `taxable`;

ALTER TABLE `ospos_customers`
  ADD COLUMN `sales_tax_code_id` int(11) DEFAULT NULL AFTER `tax_id`;

UPDATE `ospos_customers` AS fa SET fa.`sales_tax_code_id` = (
SELECT `tax_code_id` FROM `ospos_tax_codes` AS fb WHERE fa.`sales_tax_code` =  fb.`tax_code`);

ALTER TABLE `ospos_customers`
  DROP COLUMN `sales_tax_code`;

ALTER TABLE `ospos_items`
  ADD COLUMN `hsn_code` varchar(32) NOT NULL DEFAULT '' AFTER `low_sell_item_id`;

ALTER TABLE `ospos_sales_items_taxes`
  ADD COLUMN `sales_tax_code_id` int(11) DEFAULT NULL AFTER `item_tax_amount`,
  ADD COLUMN `jurisdiction_id` int(11) DEFAULT NULL AFTER `sales_tax_code_id`,
  ADD COLUMN `tax_category_id` int(11) DEFAULT NULL AFTER `jurisdiction_id`,
  DROP COLUMN `cascade_tax`;

ALTER TABLE `ospos_sales_taxes`
  ADD COLUMN `sales_tax_code_id` int(11) DEFAULT NULL AFTER `sales_tax_code`,
  ADD COLUMN `jurisdiction_id` int(11) DEFAULT NULL AFTER `sales_tax_code_id`,
  ADD COLUMN `tax_category_id` int(11) DEFAULT NULL AFTER `jurisdiction_id`;

UPDATE `ospos_sales_taxes` as fa set fa.`sales_tax_code_id` = (
SELECT `tax_code_id` FROM `ospos_tax_codes` AS fb WHERE fa.`sales_tax_code` =  fb.`tax_code`);

ALTER TABLE `ospos_sales_taxes`
  DROP COLUMN `sales_tax_code`;

ALTER TABLE `ospos_suppliers`
  ADD COLUMN `tax_id` varchar(32) NOT NULL DEFAULT '' AFTER `account_number`;

ALTER TABLE `ospos_tax_categories`
  ADD COLUMN `default_tax_rate` decimal(15,4) NOT NULL DEFAULT 0.0000 AFTER `tax_category`,
  ADD COLUMN `deleted` int(1) NOT NULL DEFAULT 0 AFTER `tax_group_sequence`;

-- The tax rates table will need to be manually set up after the upgrade
-- There are too many variables to automate the process.

DROP TABLE `ospos_tax_code_rates`;
CREATE TABLE IF NOT EXISTS `ospos_tax_rates` (
  `tax_rate_id` int(11) NOT NULL AUTO_INCREMENT,
  `rate_tax_code_id` int(11) NOT NULL,
  `rate_tax_category_id` int(10) NOT NULL,
  `rate_jurisdiction_id` int(11) NOT NULL,
  `tax_rate` decimal(15,4) NOT NULL DEFAULT 0.0000,
  `tax_rounding_code` tinyint(2) NOT NULL DEFAULT 0,
  PRIMARY KEY (`tax_rate_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `ospos_tax_jurisdictions` (
  `jurisdiction_id` int(11) NOT NULL AUTO_INCREMENT,
  `jurisdiction_name` varchar(255) DEFAULT NULL,
  `tax_type` smallint(2) NOT NULL,
  `reporting_authority` varchar(255) DEFAULT NULL,
  `tax_group_sequence` tinyint(2) NOT NULL DEFAULT 0,
  `cascade_sequence` tinyint(2) NOT NULL DEFAULT 0,
  `deleted` int(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`jurisdiction_id`),
  KEY `jurisdiction_id` (`jurisdiction_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;

-- Add support for sales tax report

INSERT INTO `ospos_permissions` (`permission_id`, `module_id`) VALUES
('reports_sales_taxes', 'reports');

INSERT INTO `ospos_grants` (`permission_id`, `person_id`, `menu_group`) VALUES
('reports_sales_taxes', 1, 'home');
