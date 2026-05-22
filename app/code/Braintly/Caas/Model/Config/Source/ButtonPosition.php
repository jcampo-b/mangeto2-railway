<?php

declare(strict_types=1);

namespace Braintly\Caas\Model\Config\Source;

use Magento\Framework\Data\OptionSourceInterface;

class ButtonPosition implements OptionSourceInterface
{
    public const BEFORE_ADDTOCART  = 'before_addtocart';
    public const AFTER_DESCRIPTION = 'after_description';
    public const AFTER_PRICE       = 'after_price';
    public const AFTER_SKU         = 'after_sku';

    public function toOptionArray(): array
    {
        return [
            [
                'value' => self::BEFORE_ADDTOCART,
                'label' => __('Before Add to Cart (recommended)'),
            ],
            [
                'value' => self::AFTER_DESCRIPTION,
                'label' => __('Bottom of Product Info Panel'),
            ],
            [
                'value' => self::AFTER_PRICE,
                'label' => __('After Price'),
            ],
            [
                'value' => self::AFTER_SKU,
                'label' => __('After SKU'),
            ],
        ];
    }
}
