module BonusHelper
  def select_bonus_calc_style
    select_tag \
      :style,
      options_for_select(
        [
          [t('bonuses.split_pot'), :split_pot],
          [t('bonuses.points_value', points_title: App.points_term.titleize), :points_value],
          [t('bonuses.salary_percent'), :salary_percent]
        ]
      ),
      id: 'bonus-calc-style'
  end
end
